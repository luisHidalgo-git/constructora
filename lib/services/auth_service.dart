import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      // Crear cliente HTTP con configuración específica para Linux
      final client = http.Client();

      final response = await http
          .post(
            Uri.parse(ApiConfig.authLogin),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      client.close();

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Guardar token y datos del usuario
        await _saveToken(data['token']);
        await _saveUser(data['user']);

        return {
          'success': true,
          'user': UserModel.fromJson(data['user']),
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Credenciales inválidas',
        };
      }
    } on SocketException catch (e) {
      return {
        'success': false,
        'message':
            'Error de conexión: Verifica que el servidor esté ejecutándose en http://127.0.0.1:3000',
      };
    } on HttpException catch (e) {
      return {'success': false, 'message': 'Error HTTP: ${e.message}'};
    } catch (e) {
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
      final response = await http
          .post(
            Uri.parse(ApiConfig.authRegister),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'role': role,
              'position': position,
            }),
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await _saveToken(data['token']);
        await _saveUser(data['user']);

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

      final response = await http
          .get(
            Uri.parse(ApiConfig.authMe),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data);
        await _saveUser(data);
        return user;
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return null;
  }

  // Verificar si está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;

    // Verificar si el token es válido
    final user = await getCurrentUser();
    return user != null;
  }

  // Obtener token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Obtener usuario guardado
  static Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Métodos privados
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }
}
