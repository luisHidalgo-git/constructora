import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/project_image_model.dart';
import '../config/api_config.dart';

class ProjectImageService {
  // Obtener headers con autorización
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'User-Agent': 'ConstructoraApp/1.0',
      'Accept': 'application/json',
    };
  }

  // Obtener headers para multipart
  static Future<Map<String, String>> _getMultipartHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'User-Agent': 'ConstructoraApp/1.0',
      'Accept': '*/*',
      'Connection': 'keep-alive',
    };
  }

  // Subir imagen a la galería del proyecto
  static Future<ProjectImageModel> uploadProjectImage({
    required String projectId,
    required String imagePath,
    String? description,
  }) async {
    try {
      print('🔍 ProjectImageService - Uploading image to project gallery...');
      print('🔍 Project ID: $projectId');
      print('🔍 Image path: $imagePath');

      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!file.existsSync()) {
        throw Exception('El archivo de imagen no existe: $imagePath');
      }

      final fileSize = file.lengthSync();
      print('✅ ProjectImageService - File exists, size: $fileSize bytes');

      // Verificar tamaño del archivo (máximo 10MB)
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('La imagen es demasiado grande. Máximo 10MB permitido.');
      }

      final headers = await _getMultipartHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/project-images/$projectId');

      print('🔍 ProjectImageService - Uploading to: $uri');

      // Crear request multipart
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      // Agregar descripción si existe
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }

      // Determinar el tipo MIME correcto
      final extension = path.extension(imagePath).toLowerCase();
      MediaType? mediaType;
      switch (extension) {
        case '.jpg':
        case '.jpeg':
          mediaType = MediaType('image', 'jpeg');
          break;
        case '.png':
          mediaType = MediaType('image', 'png');
          break;
        default:
          mediaType = MediaType('image', 'jpeg');
      }

      var multipartFile = await http.MultipartFile.fromPath(
        'image',
        imagePath,
        contentType: mediaType,
      );
      request.files.add(multipartFile);

      print('🔍 ProjectImageService - Sending multipart request...');

      // Enviar request
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      var response = await http.Response.fromStream(streamedResponse);

      print('🔍 ProjectImageService - Response status: ${response.statusCode}');
      print('🔍 ProjectImageService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ ProjectImageService - Image uploaded successfully to project gallery');
        return ProjectImageModel.fromJson(data['image']);
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Error al subir imagen a la galería');
        } catch (e) {
          throw Exception('Error del servidor: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ ProjectImageService - Error uploading image: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Error de conexión: ${e.toString()}');
      }
    }
  }

  // Obtener todas las imágenes de un proyecto
  static Future<List<ProjectImageModel>> getProjectImages(String projectId) async {
    try {
      print('🔍 ProjectImageService - Getting images for project: $projectId');

      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/project-images/$projectId'),
            headers: headers,
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      print('🔍 ProjectImageService - Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> imagesData = data['images'];
        
        print('✅ ProjectImageService - Found ${imagesData.length} images');
        
        return imagesData.map((json) => ProjectImageModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener imágenes del proyecto: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ProjectImageService - Error getting images: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Eliminar imagen de la galería
  static Future<bool> deleteProjectImage(String imageId) async {
    try {
      print('🔍 ProjectImageService - Deleting image: $imageId');

      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/project-images/$imageId'),
            headers: headers,
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      print('🔍 ProjectImageService - Delete response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ ProjectImageService - Image deleted successfully');
        return true;
      } else {
        print('❌ ProjectImageService - Failed to delete image: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ ProjectImageService - Error deleting image: $e');
      return false;
    }
  }

  // Actualizar descripción de imagen
  static Future<bool> updateImageDescription(String imageId, String description) async {
    try {
      print('🔍 ProjectImageService - Updating image description: $imageId');

      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/project-images/$imageId'),
            headers: headers,
            body: jsonEncode({'description': description}),
          )
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      print('🔍 ProjectImageService - Update response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ ProjectImageService - Image description updated successfully');
        return true;
      } else {
        print('❌ ProjectImageService - Failed to update description: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ ProjectImageService - Error updating description: $e');
      return false;
    }
  }
}