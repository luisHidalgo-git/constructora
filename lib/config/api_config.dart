import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static String get baseUrl {
    try {
      String url = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:3000/api';
      
      // Debug de la URL
      print('🔗 API Base URL: $url');
      
      return url;
    } catch (e) {
      print('❌ Error loading API_BASE_URL: $e');
      return 'http://127.0.0.1:3000/api';
    }
  }

  static int get timeout {
    try {
      final timeout = int.parse(dotenv.env['API_TIMEOUT'] ?? '60000');
      print('⏱️ API Timeout: ${timeout}ms');
      return timeout;
    } catch (e) {
      print('❌ Error loading API_TIMEOUT: $e');
      return 60000;
    }
  }

  // Endpoints
  static String get authLogin => '$baseUrl/auth/login';
  static String get authRegister => '$baseUrl/auth/register';
  static String get authMe => '$baseUrl/auth/me';
  static String get projects => '$baseUrl/projects';
  static String get activities => '$baseUrl/activities';
  static String get stats => '$baseUrl/stats';

  static String projectById(String id) => '$projects/$id';
  static String activitiesByProject(String projectId) =>
      '$activities/project/$projectId';
  static String activityById(String id) => '$activities/$id';

  // Método para verificar la conectividad
  static Future<bool> checkConnectivity() async {
    try {
      print('🔍 Checking connectivity to: $baseUrl');
      final healthUrl = baseUrl.replaceAll('/api', '/health');
      print('🔍 Health check URL: $healthUrl');
      
      final response = await http.get(
        Uri.parse(healthUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 15));
      
      print('🔍 Health check status: ${response.statusCode}');
      print('🔍 Health check response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connectivity check failed: $e');
      return false;
    }
  }
}
