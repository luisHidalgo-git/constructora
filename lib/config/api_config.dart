import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';
  static int get timeout => int.parse(dotenv.env['API_TIMEOUT'] ?? '30000');
  
  // Endpoints
  static String get authLogin => '$baseUrl/auth/login';
  static String get authRegister => '$baseUrl/auth/register';
  static String get authMe => '$baseUrl/auth/me';
  static String get projects => '$baseUrl/projects';
  static String get activities => '$baseUrl/activities';
  static String get stats => '$baseUrl/stats';
  
  static String projectById(String id) => '$projects/$id';
  static String activitiesByProject(String projectId) => '$activities/project/$projectId';
  static String activityById(String id) => '$activities/$id';
}