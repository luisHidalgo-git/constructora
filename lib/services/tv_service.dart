import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class TVService {
  // Obtener headers con autorización
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Conectar teléfono a sesión de TV
  static Future<Map<String, dynamic>> connectToTV(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/tv/connect'),
            headers: headers,
            body: jsonEncode({'sessionId': sessionId}),
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'sessionId': data['sessionId'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error conectando a la TV',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Desconectar de sesión de TV
  static Future<Map<String, dynamic>> disconnectFromTV(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/tv/disconnect'),
            headers: headers,
            body: jsonEncode({'sessionId': sessionId}),
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error desconectando de la TV',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Obtener estado de sesión de TV
  static Future<Map<String, dynamic>> getSessionStatus(String sessionId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/tv/session/$sessionId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'sessionId': data['sessionId'],
          'isConnected': data['isConnected'],
          'user': data['user'],
          'connectedAt': data['connectedAt'],
          'expiresAt': data['expiresAt'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo estado de sesión',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Generar nuevo QR para TV
  static Future<Map<String, dynamic>> generateQR() async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/tv/generate-qr'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'sessionId': data['sessionId'],
          'qrCode': data['qrCode'],
          'expiresIn': data['expiresIn'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error generando código QR',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }
}