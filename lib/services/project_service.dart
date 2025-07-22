import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/project_model.dart';
import '../services/image_service.dart';

class ProjectService {
  // Obtener headers con autorización
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Obtener todos los proyectos
  static Future<List<ProjectModel>> getProjects() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.projects), headers: headers)
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ProjectModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener proyectos: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception(
        'Error de conexión: Verifica que el servidor esté ejecutándose',
      );
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Obtener proyecto por ID
  static Future<ProjectModel> getProject(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.projectById(id)), headers: headers)
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProjectModel.fromJson(data);
      } else {
        throw Exception('Error al obtener proyecto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  // Crear proyecto
  static Future<ProjectModel> createProject(ProjectModel project) async {
    try {
      final headers = await _getHeaders();
      
      // Procesar imagen automáticamente antes de crear el proyecto
      String processedImageUrl = await ImageService.processImageForProject(project.imageUrl);
      print('🔍 Creating project with processed image URL: $processedImageUrl');
      
      // Crear proyecto con imagen procesada
      final projectData = project.copyWith(imageUrl: processedImageUrl).toCreateJson();
      
      final response = await http
          .post(
            Uri.parse(ApiConfig.projects),
            headers: headers,
            body: jsonEncode(projectData),
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ProjectModel.fromJson(data['project']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al crear proyecto');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  // Actualizar proyecto
  static Future<ProjectModel> updateProject(
    String id,
    ProjectModel project,
  ) async {
    try {
      final headers = await _getHeaders();
      
      // Procesar imagen automáticamente antes de actualizar el proyecto
      String processedImageUrl = await ImageService.processImageForProject(project.imageUrl);
      print('🔍 Updating project with processed image URL: $processedImageUrl');
      
      // Actualizar proyecto con imagen procesada
      final projectData = project.copyWith(imageUrl: processedImageUrl).toUpdateJson();
      
      final response = await http
          .put(
            Uri.parse(ApiConfig.projectById(id)),
            headers: headers,
            body: jsonEncode(projectData),
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProjectModel.fromJson(data['project']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al actualizar proyecto');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  // Eliminar proyecto
  static Future<bool> deleteProject(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(Uri.parse(ApiConfig.projectById(id)), headers: headers)
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }
}
