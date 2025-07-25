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
  static String? _currentScreen = 'home'; // Rastrear pantalla actual
  static String? _currentProjectId; // Rastrear proyecto actual

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
    _currentScreen = null;
    _currentProjectId = null;
    
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
        'eventId': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      print('📱 Mobile -> Server: Sending navigation event: $eventType with data: ${data ?? {}}');
      
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/sync/navigation'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));

      print('✅ Mobile: Navigation event sent successfully: $eventType');
    } catch (e) {
      print('❌ Mobile: Error sending navigation event $eventType: $e');
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
            print('📺 TV: Received ${events.length} sync events');
            for (var event in events) {
              print('📺 TV: Processing event: ${event['eventType']}');
              _handleNavigationEvent(event);
            }
          }
        }
      } catch (e) {
        // Silenciar errores de polling para no saturar logs
        // print('❌ Error polling navigation events: $e');
      }
    });
  }

  // Manejar eventos recibidos
  static void _handleNavigationEvent(Map<String, dynamic> event) {
    final userId = event['userId'];
    final eventType = event['eventType'];
    print('📺 TV: Handling navigation event: $eventType for user: $userId');
    
    if (_controllers.containsKey(userId) && !_controllers[userId]!.isClosed) {
      _controllers[userId]!.add(event);
      print('📺 TV: Event sent to stream controller for user: $userId');
    } else {
      print('📺 TV: No active stream controller for user: $userId');
    }
  }

  static void clearProjectState() {
    _currentProjectId = null;
  }

  // Eventos específicos de navegación
  static Future<void> navigateToHome() async {
    print('📱 Mobile: Triggering navigate_to_home event');
    _currentScreen = 'home';
    _currentProjectId = null;
    await sendNavigationEvent(eventType: 'navigate_to_home');
  }

  static Future<void> navigateToProjects() async {
    print('📱 Mobile: Triggering navigate_to_projects event');
    _currentScreen = 'projects';
    _currentProjectId = null;
    await sendNavigationEvent(eventType: 'navigate_to_projects');
  }

  static Future<void> navigateToProjectDetail(String projectId) async {
    print('📱 Mobile: Triggering navigate_to_project_detail event for project: $projectId');
    
    // Limpiar estado anterior antes de navegar
    if (_currentProjectId != projectId) {
      clearProjectState();
    }
    
    _currentScreen = 'project_detail';
    _currentProjectId = projectId;
    await sendNavigationEvent(
      eventType: 'navigate_to_project_detail',
      data: {'projectId': projectId},
    );
  }

  static Future<void> navigateBackToHome() async {
    print('📱 Mobile: Triggering navigate_back_to_home event');
    _currentScreen = 'home';
    _currentProjectId = null;
    await sendNavigationEvent(eventType: 'navigate_back_to_home');
  }

  static Future<void> navigateBackToProjects() async {
    print('📱 Mobile: Triggering navigate_back_to_projects event');
    _currentScreen = 'projects';
    _currentProjectId = null;
    await sendNavigationEvent(eventType: 'navigate_back_to_projects');
  }

  static Future<void> navigateBackToDashboard() async {
    print('📱 Mobile: Triggering navigate_back_to_dashboard event');
    _currentScreen = 'home';
    _currentProjectId = null;
    await sendNavigationEvent(eventType: 'navigate_back_to_dashboard');
  }

  // Eventos de actualización de datos
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
    _currentScreen = null;
    _currentProjectId = null;
    stopSync();
  }

  // Getters para estado actual
  static String? get currentScreen => _currentScreen;
  static String? get currentProjectId => _currentProjectId;

  // Métodos para actualizar estado interno sin enviar eventos
  static void setCurrentScreen(String screen) {
    _currentScreen = screen;
  }

  static void setCurrentProjectId(String? projectId) {
    _currentProjectId = projectId;
  }

  // Método para forzar limpieza de estado
  static void forceCleanState() {
    _currentScreen = null;
    _currentProjectId = null;
  }

  // Método para forzar sincronización del estado actual
  static Future<void> syncCurrentState() async {
    if (_currentScreen != null) {
      switch (_currentScreen) {
        case 'home':
          await navigateToHome();
          break;
        case 'projects':
          await navigateToProjects();
          break;
        case 'project_detail':
          if (_currentProjectId != null) {
            await navigateToProjectDetail(_currentProjectId!);
          }
          break;
      }
    }
  }
}