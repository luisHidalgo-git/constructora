import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    try {
      // Usar Railway como servidor principal
      String url = dotenv.env['API_BASE_URL'] ?? 'https://constructora-production-beec.up.railway.app/api';
      
      // Debug de la URL
      print('🔗 API Base URL: $url');
      print('🔗 Release Mode: $kReleaseMode');
      
      return url;
    } catch (e) {
      print('❌ Error loading API_BASE_URL: $e');
      // Fallback al servidor de Railway
      return 'https://constructora-production-beec.up.railway.app/api';
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
  static String get tvAuth => '$baseUrl/tv-auth';

  static String projectById(String id) => '$projects/$id';
  static String activitiesByProject(String projectId) =>
      '$activities/project/$projectId';
  static String activityById(String id) => '$activities/$id';
  
  // TV Auth endpoints
  static String get tvAuthGenerateQR => '$tvAuth/generate-qr';
  static String get tvAuthScanQR => '$tvAuth/scan-qr';
  static String tvAuthCheckStatus(String qrCode) => '$tvAuth/check-status/$qrCode';

  // Método para verificar la conectividad
  static Future<bool> checkConnectivity() async {
    try {
      print('🔍 ApiConfig - Checking connectivity to: $baseUrl');
      final healthUrl = serverBaseUrl + '/health';
      print('🔍 ApiConfig - Health check URL: $healthUrl');
      
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
      
      print('🔍 ApiConfig - Health check status: ${response.statusCode}');
      print('🔍 ApiConfig - Health check response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ ApiConfig - Connectivity check failed: $e');
      return false;
    }
  }

  // Método para verificar si una imagen del servidor existe
  static Future<bool> checkImageUrl(String imageUrl) async {
    try {
      print('🔍 ApiConfig - Checking image URL: $imageUrl');
      
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent': 'ConstructoraApp/1.0',
          'Accept': 'image/*',
        },
      ).timeout(Duration(seconds: 10));
      
      print('🔍 ApiConfig - Image check status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ ApiConfig - Error checking image URL: $e');
      return false;
    }
  }

  // Método para obtener la URL base del servidor (sin /api)
  static String get serverBaseUrl {
    return baseUrl.replaceAll('/api', '');
  }
}
