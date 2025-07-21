import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Método para debug de la URL
  static void _debugApiCall(String endpoint, Map<String, dynamic> body) {
    print('🔗 API Call Debug:');
    print('   Endpoint: $endpoint');
    print('   Body: ${jsonEncode(body)}');
  }

  // Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final requestBody = {'email': email, 'password': password};

      // Debug de la llamada
      _debugApiCall(ApiConfig.authLogin, requestBody);

      // Headers mejorados para el backend desplegado
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'ConstructoraApp/1.0',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Accept-Encoding': 'gzip, deflate',
      };

      print('🔍 Request headers: $headers');
      print('🔍 Request URL: ${ApiConfig.authLogin}');
      print('🔍 Request body: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(ApiConfig.authLogin),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(
            Duration(milliseconds: ApiConfig.timeout * 2),
          ); // Timeout más largo para release

      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Headers: ${response.headers}');
      print('🔍 Response Body: ${response.body}');

      // Verificar si la respuesta es válida
      if (response.body.isEmpty) {
        print('❌ Empty response body');
        return {'success': false, 'message': 'Respuesta vacía del servidor'};
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print('❌ JSON decode error: $e');
        print('❌ Raw response: ${response.body}');
        return {
          'success': false,
          'message': 'Error en el formato de respuesta del servidor',
        };
      }

      if (response.statusCode == 200) {
        // Guardar token y datos del usuario
        await _saveToken(data['token']);
        await _saveUser(data['user']);

        print('✅ Login successful, token saved');
        return {
          'success': true,
          'user': UserModel.fromJson(data['user']),
          'token': data['token'],
        };
      } else {
        print('❌ Login failed with status: ${response.statusCode}');
        print('❌ Error response: ${response.body}');
        return {
          'success': false,
          'message': data['message'] ?? 'Credenciales inválidas',
        };
      }
    } on SocketException catch (e) {
      print('❌ Socket Exception: $e');
      return {
        'success': false,
        'message':
            'Error de conexión: No se puede conectar al servidor. Verifica tu conexión a internet.',
      };
    } on TimeoutException catch (e) {
      print('❌ Timeout Exception: $e');
      return {
        'success': false,
        'message':
            'Tiempo de espera agotado. El servidor puede estar sobrecargado.',
      };
    } on HttpException catch (e) {
      print('❌ HTTP Exception: $e');
      return {'success': false, 'message': 'Error HTTP: ${e.message}'};
    } on FormatException catch (e) {
      print('❌ Format Exception: $e');
      return {
        'success': false,
        'message': 'Error en el formato de respuesta del servidor',
      };
    } catch (e) {
      print('❌ General Exception: $e');
      return {'success': false, 'message': 'Error inesperado: ${e.toString()}'};
    }
  }

  // Registro
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'supervisor',
    String position = 'Supervisor',
  }) async {
    try {
      final requestBody = {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'position': position,
      };

      // Debug de la llamada
      _debugApiCall(ApiConfig.authRegister, requestBody);

      final response = await http
          .post(
            Uri.parse(ApiConfig.authRegister),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'ConstructoraApp/1.0',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      print('🔍 Register Response Status: ${response.statusCode}');
      print('🔍 Register Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await _saveToken(data['token']);
        await _saveUser(data['user']);

        print('✅ Registration successful, token saved');
        return {
          'success': true,
          'user': UserModel.fromJson(data['user']),
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error en el registro',
        };
      }
    } catch (e) {
      print('❌ Register Exception: $e');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Obtener perfil actual
  static Future<UserModel?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      print('🔍 Getting current user with token: ${token.substring(0, 20)}...');
      final response = await http
          .get(
            Uri.parse(ApiConfig.authMe),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
              'User-Agent': 'ConstructoraApp/1.0',
            },
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      print('🔍 Current user response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data);
        await _saveUser(data);
        print('✅ Current user retrieved successfully');
        return user;
      } else {
        print('❌ Failed to get current user: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return null;
  }

  // Verificar si está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) {
      print('❌ No token found');
      return false;
    }

    print('🔍 Token found, verifying with server...');
    // Verificar si el token es válido
    final user = await getCurrentUser();
    final isAuth = user != null;
    print(isAuth ? '✅ User is authenticated' : '❌ User is not authenticated');
    return isAuth;
  }

  // Obtener token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      print('🔍 Token retrieved from storage: ${token.substring(0, 20)}...');
    } else {
      print('❌ No token found in storage');
    }
    return token;
  }

  // Obtener usuario guardado
  static Future<UserModel?> getSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        print('✅ Saved user data found');
        return UserModel.fromJson(jsonDecode(userData));
      } else {
        print('❌ No saved user data found');
      }
    } catch (e) {
      print('Error getting saved user: $e');
    }
    return null;
  }

  // Logout
  static Future<void> logout() async {
    print('🔍 Logging out user...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    print('✅ User logged out, tokens cleared');
  }

  // Métodos privados
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('✅ Token saved to storage');
  }

  static Future<void> _saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
    print('✅ User data saved to storage');
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    // Implementa aquí el guardado de usuario (ejemplo usando SharedPreferences)
  }

  static Future<void> saveToken(String token) async {
    // Implementa aquí el guardado de token (ejemplo usando SharedPreferences)
  }
}
