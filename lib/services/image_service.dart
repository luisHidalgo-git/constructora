import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class ImageService {
  // Obtener headers con autorización
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  // Subir imagen al servidor
  static Future<String> uploadImage(String imagePath) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/upload/image');
      
      // Crear request multipart
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      
      // Agregar archivo
      var file = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(file);
      
      // Enviar request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['imageUrl'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al subir imagen');
      }
      
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  // Eliminar imagen del servidor
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extraer filename de la URL
      final uri = Uri.parse(imageUrl);
      final filename = uri.pathSegments.last;
      
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/upload/image/$filename'),
        headers: headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Verificar si una URL es una imagen local o del servidor
  static bool isServerImage(String imageUrl) {
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  // Verificar si una URL es una imagen local del dispositivo
  static bool isLocalImage(String imageUrl) {
    return imageUrl.startsWith('file://') || imageUrl.startsWith('/');
  }
}