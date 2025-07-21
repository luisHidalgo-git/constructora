import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    try {
      // Siempre usar el servidor desplegado para mayor estabilidad
      String url = dotenv.env['API_BASE_URL'] ?? 'https://backend-constructora-klfi.onrender.com/api';
      
      // Debug de la URL
      print('🔗 API Base URL: $url');
      print('🔗 Release Mode: $kReleaseMode');
      
      return url;
    } catch (e) {
      print('❌ Error loading API_BASE_URL: $e');
      // Fallback al servidor desplegado
      return 'https://backend-constructora-klfi.onrender.com/api';
    }
  }

  static int get timeout {
    try {
      final timeout = int.parse(dotenv.env['API_TIMEOUT'] ?? '45000');
      print('⏱️ API Timeout: ${timeout}ms');
      return timeout;
    } catch (e) {
      print('❌ Error loading API_TIMEOUT: $e');
      return 45000;
    }
  }

  // Endpoints
  static String get authLogin => '$baseUrl/auth/login';
  static String get authRegister => '$baseUrl/auth/register';
  static String get authMe => '$baseUrl/auth/me';
  static String get projects => '$baseUrl/projects';
  static String get activities => '$baseUrl/activities';
  static String get stats => '$baseUrl/stats';
  static String get upload => '$baseUrl/upload';

  static String projectById(String id) => '$projects/$id';
  static String activitiesByProject(String projectId) =>
      '$activities/project/$projectId';
  static String activityById(String id) => '$activities/$id';

  // Método para verificar la conectividad
  static Future<bool> checkConnectivity() async {
    try {
      print('🔍 Checking connectivity to: $baseUrl');
      final healthUrl = serverBaseUrl + '/health';
      print('🔍 Health check URL: $healthUrl');
      
      final response = await http.get(
        Uri.parse(healthUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'ConstructoraApp/1.0',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
        },
      ).timeout(Duration(seconds: 25));
      
      print('🔍 Health check status: ${response.statusCode}');
      print('🔍 Health check response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connectivity check failed: $e');
      return false;
    }
  }

  // Método para obtener la URL base del servidor (sin /api)
  static String get serverBaseUrl {
    return baseUrl.replaceAll('/api', '');
  }
}
