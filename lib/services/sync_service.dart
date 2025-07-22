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

  // Obtener stream para un usuario específico
  static Stream<Map<String, dynamic>> getNavigationStream(String userId) {
    if (!_controllers.containsKey(userId)) {
      _controllers[userId] = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _controllers[userId]!.stream;
  }

  // Iniciar sincronización para un usuario
  static Future<void> startSync(String userId) async {
    _currentUserId = userId;
    if (!_isPolling) {
      _isPolling = true;
      _startPolling();
    }
  }

  // Detener sincronización
  static void stopSync() {
    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _currentUserId = null;
    
    // Cerrar todos los streams
    for (var controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
  }

  // Enviar evento de navegación
  static Future<void> sendNavigationEvent({
    required String eventType,
    Map<String, dynamic>? data,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = {
        'eventType': eventType,
        'data': data ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/sync/navigation'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));

      print('✅ Navigation event sent: $eventType');
    } catch (e) {
      print('❌ Error sending navigation event: $e');
    }
  }

  // Polling para recibir eventos
  static void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isPolling || _currentUserId == null) {
        timer.cancel();
        return;
      }

      try {
        final token = await AuthService.getToken();
        if (token == null) return;

        final headers = {
          'Authorization': 'Bearer $token',
        };

        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/sync/navigation'),
          headers: headers,
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['hasEvents'] == true) {
            final events = data['events'] as List;
            for (var event in events) {
              _handleNavigationEvent(event);
            }
          }
        }
      } catch (e) {
        print('❌ Error polling navigation events: $e');
      }
    });
  }

  // Manejar eventos recibidos
  static void _handleNavigationEvent(Map<String, dynamic> event) {
    final userId = event['userId'];
    if (_controllers.containsKey(userId) && !_controllers[userId]!.isClosed) {
      _controllers[userId]!.add(event);
    }
  }

  // Eventos específicos
  static Future<void> navigateToProjects() async {
    await sendNavigationEvent(eventType: 'navigate_to_projects');
  }

  static Future<void> navigateToProjectDetail(String projectId) async {
    await sendNavigationEvent(
      eventType: 'navigate_to_project_detail',
      data: {'projectId': projectId},
    );
  }

  static Future<void> projectUpdated(Map<String, dynamic> projectData) async {
    await sendNavigationEvent(
      eventType: 'project_updated',
      data: {'project': projectData},
    );
  }

  static Future<void> projectCreated(Map<String, dynamic> projectData) async {
    await sendNavigationEvent(
      eventType: 'project_created',
      data: {'project': projectData},
    );
  }

  static Future<void> logout() async {
    await sendNavigationEvent(eventType: 'logout');
    stopSync();
  }
}