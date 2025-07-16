import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/stats_model.dart';

class StatsService {
  // Obtener headers con autorización
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Obtener estadísticas
  static Future<StatsModel> getStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.stats), headers: headers)
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StatsModel.fromJson(data);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception(
        'Error de conexión: Verifica que el servidor esté ejecutándose',
      );
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }
}