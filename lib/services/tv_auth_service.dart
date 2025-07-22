import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class TVAuthService {
  // Generar código QR para TV
  static Future<Map<String, dynamic>> generateQRCode() async {
    try {
      print('🔍 Generating QR code for TV...');

      final response = await http.post(
        Uri.parse(ApiConfig.tvAuthGenerateQR),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(milliseconds: ApiConfig.timeout));

      print('🔍 Generate QR response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ QR code generated successfully');
        return {
          'success': true,
          'qrCode': data['qrCode'],
          'expiresAt': DateTime.parse(data['expiresAt']),
        };
      } else {
        print('❌ Failed to generate QR code: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Error generating QR code',
        };
      }
    } catch (e) {
      print('❌ Exception generating QR code: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Escanear código QR desde móvil
  static Future<Map<String, dynamic>> scanQRCode(String qrCode) async {
    try {
      print('🔍 Scanning QR code: $qrCode');

      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ No authentication token found');
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      print('🔍 Using token: ${token.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse(ApiConfig.tvAuthScanQR),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'User-Agent': 'ConstructoraApp/1.0',
        },
        body: jsonEncode({'qrCode': qrCode}),
      ).timeout(Duration(milliseconds: ApiConfig.timeout));

      print('🔍 Scan QR response: ${response.statusCode}');
      print('🔍 Scan QR response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ QR code scanned successfully');
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        Map<String, dynamic> error;
        try {
          error = jsonDecode(response.body);
        } catch (e) {
          error = {'message': 'Error parsing server response'};
        }
        print('❌ Failed to scan QR code: ${error['message']}');
        return {
          'success': false,
          'message': error['message'] ?? 'Error scanning QR code',
        };
      }
    } catch (e) {
      print('❌ Exception scanning QR code: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Verificar estado del código QR (para TV)
  static Future<Map<String, dynamic>> checkQRStatus(String qrCode) async {
    try {
      print('🔍 Checking QR status for: $qrCode');
      
      final response = await http.get(
        Uri.parse(ApiConfig.tvAuthCheckStatus(qrCode)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'ConstructoraApp/1.0',
        },
      ).timeout(Duration(milliseconds: ApiConfig.timeout));

      print('🔍 Check status response: ${response.statusCode}');
      print('🔍 Check status body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'status': data['status'],
          'message': data['message'],
          'user': data['user'],
          'expiresAt': data['expiresAt'] != null 
              ? DateTime.parse(data['expiresAt']) 
              : null,
        };
      } else {
        print('❌ Error response: ${response.body}');
        return {
          'success': false,
          'status': 'error',
          'message': 'Error checking QR status',
        };
      }
    } catch (e) {
      print('❌ Exception checking QR status: $e');
      return {
        'success': false,
        'status': 'error',
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
}