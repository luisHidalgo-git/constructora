import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class SyncService {
  static final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};
  static Timer? _pollTimer;
  static String? _currentUserId;
  static bool _isPolling = false;
  static String? _lastEventId; // Para evitar procesar el mismo evento múltiples veces

  // Obtener stream para un usuario específico
  static Stream<Map<String, dynamic>> getNavigationStream(String userId) {
    if (!_controllers.containsKey(userId)) {
      _controllers[userId] = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _controllers[userId]!.stream;
  }

  // Iniciar sincronización para un usuario
  static Future<void> startSync(String userId) async {
    print('🔄 SyncService: Starting sync for user: $userId');
    _currentUserId = userId;
    if (!_isPolling) {
      _isPolling = true;
      _startPolling();
      print('✅ SyncService: Polling started for user: $userId');
    } else {
      print('✅ SyncService: Polling already active for user: $userId');
    }
  }

  // Detener sincronización
  static void stopSync() {
    print('🔄 SyncService: Stopping sync...');
    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _currentUserId = null;
    _lastEventId = null;
    
    // NO cerrar los streams, mantenerlos activos para reconexión
    print('✅ SyncService: Sync stopped but streams kept alive');
  }

  // Limpiar completamente (solo en logout)
  static void clearAll() {
    print('🔄 SyncService: Clearing all sync data...');
    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _currentUserId = null;
    _lastEventId = null;
    
    // Cerrar todos los streams
    for (var controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
    print('✅ SyncService: All sync data cleared');
  }

  // Enviar evento de navegación
  static Future<void> sendNavigationEvent({
    required String eventType,
    Map<String, dynamic>? data,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ SyncService: No token available for sending event: $eventType');
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final eventId = DateTime.now().millisecondsSinceEpoch.toString();
      final body = {
        'eventType': eventType,
        'data': data ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'eventId': eventId,
      };

      print('📱 Mobile: Sending navigation event: $eventType with data: ${data ?? {}} (ID: $eventId)');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/sync/navigation'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Mobile: Navigation event sent successfully: $eventType (ID: $eventId)');
      } else {
        print('❌ Mobile: Failed to send navigation event: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Mobile: Error sending navigation event $eventType: $e');
    }
  }

  // Polling mejorado para recibir eventos
  static void _startPolling() {
    print('🔄 SyncService: Starting polling timer...');
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isPolling || _currentUserId == null) {
        print('⚠️ SyncService: Polling stopped - isPolling: $_isPolling, userId: $_currentUserId');
        timer.cancel();
        return;
      }

      try {
        final token = await AuthService.getToken();
        if (token == null) {
          print('❌ SyncService: No token available for polling');
          return;
        }

        final headers = {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        };

        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/sync/navigation'),
          headers: headers,
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['hasEvents'] == true) {
            final events = data['events'] as List;
            print('📺 TV: Received ${events.length} sync events');
            
            for (var event in events) {
              final eventId = event['eventId']?.toString();
              
              // Evitar procesar el mismo evento múltiples veces
              if (eventId != null && eventId == _lastEventId) {
                print('⚠️ TV: Skipping duplicate event: ${event['eventType']} (ID: $eventId)');
                continue;
              }
              
              _lastEventId = eventId;
              print('📺 TV: Processing new event: ${event['eventType']} (ID: $eventId)');
              _handleNavigationEvent(event);
            }
          }
        } else if (response.statusCode != 200) {
          print('⚠️ SyncService: Polling error: ${response.statusCode}');
        }
      } catch (e) {
        // Solo loggear errores críticos para no saturar
        if (e.toString().contains('TimeoutException') || 
            e.toString().contains('SocketException')) {
          // Silenciar errores de conectividad comunes
        } else {
          print('❌ SyncService: Polling error: $e');
        }
      }
    });
  }

  // Manejar eventos recibidos con mejor lógica
  static void _handleNavigationEvent(Map<String, dynamic> event) {
    final userId = event['userId'];
    final eventType = event['eventType'];
    final eventId = event['eventId'];
    
    print('📺 TV: Handling navigation event: $eventType for user: $userId (ID: $eventId)');
    
    if (_controllers.containsKey(userId) && !_controllers[userId]!.isClosed) {
      // Agregar timestamp de procesamiento para debugging
      event['processedAt'] = DateTime.now().toIso8601String();
      
      _controllers[userId]!.add(event);
      print('✅ TV: Event sent to stream controller for user: $userId');
    } else {
      print('❌ TV: No active stream controller for user: $userId');
      
      // Recrear controller si no existe
      if (!_controllers.containsKey(userId)) {
        _controllers[userId] = StreamController<Map<String, dynamic>>.broadcast();
        print('🔄 TV: Created new stream controller for user: $userId');
      }
    }
  }

  // Eventos específicos con mejor logging
  static Future<void> navigateToProjects() async {
    print('📱 Mobile: Triggering navigate_to_projects event');
    await sendNavigationEvent(eventType: 'navigate_to_projects');
  }

  static Future<void> navigateToHome() async {
    print('📱 Mobile: Triggering navigate_to_home event');
    await sendNavigationEvent(eventType: 'navigate_to_home');
  }

  static Future<void> navigateToProjectDetail(String projectId) async {
    print('📱 Mobile: Triggering navigate_to_project_detail event for project: $projectId');
    await sendNavigationEvent(
      eventType: 'navigate_to_project_detail',
      data: {'projectId': projectId},
    );
  }

  static Future<void> navigateBackToHome() async {
    print('📱 Mobile: Triggering navigate_back_to_home event');
    await sendNavigationEvent(eventType: 'navigate_back_to_home');
  }

  static Future<void> projectUpdated(Map<String, dynamic> projectData) async {
    print('📱 Mobile: Triggering project_updated event');
    await sendNavigationEvent(
      eventType: 'project_updated',
      data: {'project': projectData},
    );
  }

  static Future<void> projectCreated(Map<String, dynamic> projectData) async {
    print('📱 Mobile: Triggering project_created event');
    await sendNavigationEvent(
      eventType: 'project_created',
      data: {'project': projectData},
    );
  }

  static Future<void> logout() async {
    print('📱 Mobile: Triggering logout event');
    await sendNavigationEvent(eventType: 'logout');
    clearAll(); // Limpiar completamente en logout
  }

  // Método para reconectar sincronización
  static Future<void> reconnectSync() async {
    if (_currentUserId != null) {
      print('🔄 SyncService: Reconnecting sync for user: $_currentUserId');
      await startSync(_currentUserId!);
    }
  }

  // Verificar estado de sincronización
  static bool get isActive => _isPolling && _currentUserId != null;
  static String? get currentUserId => _currentUserId;
}