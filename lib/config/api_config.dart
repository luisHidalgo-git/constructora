import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    try {
      // Para desarrollo en Linux, usar 127.0.0.1 en lugar de localhost
      String url = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:3000/api';
      // Reemplazar localhost con 127.0.0.1 si existe
      if (url.contains('localhost')) {
        url = url.replaceAll('localhost', '127.0.0.1');
      }
      return url;
    } catch (e) {
      return 'http://127.0.0.1:3000/api';
    }
  }

  static int get timeout {
    try {
      return int.parse(dotenv.env['API_TIMEOUT'] ?? '30000');
    } catch (e) {
      return 30000;
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
}
