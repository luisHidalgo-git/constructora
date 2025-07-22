import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/activity_model.dart';

class ActivityService {
  // Obtener headers con autorización
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Obtener todas las actividades
  static Future<List<ActivityModel>> getActivities() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.activities), headers: headers)
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ActivityModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener actividades: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception(
        'Error de conexión: Verifica que el servidor esté ejecutándose',
      );
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Obtener actividades por proyecto
  static Future<List<ActivityModel>> getActivitiesByProject(String projectId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.activitiesByProject(projectId)), headers: headers)
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ActivityModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener actividades del proyecto: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception(
        'Error de conexión: Verifica que el servidor esté ejecutándose',
      );
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Crear actividad
  static Future<ActivityModel> createActivity(ActivityModel activity) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(ApiConfig.activities),
            headers: headers,
            body: jsonEncode(activity.toCreateJson()),
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ActivityModel.fromJson(data['activity']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al crear actividad');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  // Actualizar actividad
  static Future<ActivityModel> updateActivity(
    String id,
    ActivityModel activity,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse(ApiConfig.activityById(id)),
            headers: headers,
            body: jsonEncode(activity.toUpdateJson()),
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ActivityModel.fromJson(data['activity']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al actualizar actividad');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }
}