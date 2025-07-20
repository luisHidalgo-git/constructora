import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class ImageService {
  // Obtener headers con autorización
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'User-Agent': 'ConstructoraApp/1.0',
    };
  }

  // Obtener headers para multipart
  static Future<Map<String, String>> _getMultipartHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'User-Agent': 'ConstructoraApp/1.0',
      // No incluir Content-Type para multipart, se establece automáticamente
    };
  }

  // Subir imagen al servidor
  static Future<String> uploadImage(String imagePath) async {
    try {
      print('🔍 Starting image upload process...');
      print('🔍 Image path: $imagePath');

      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!file.existsSync()) {
        throw Exception('El archivo de imagen no existe: $imagePath');
      }

      print('✅ Image file exists, size: ${file.lengthSync()} bytes');

      final headers = await _getMultipartHeaders();
      final uri = Uri.parse('${ApiConfig.upload}/image');

      print('🔍 Uploading image to: $uri');
      print('🔍 Headers: $headers');

      // Crear request multipart
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      // Agregar archivo
      var multipartFile = await http.MultipartFile.fromPath(
        'image',
        imagePath,
        // Si necesitas especificar el tipo MIME:
        // contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      print('🔍 Sending multipart request...');

      // Enviar request
      var streamedResponse = await request.send().timeout(
        Duration(milliseconds: ApiConfig.timeout),
      );
      var response = await http.Response.fromStream(streamedResponse);

      print('🔍 Upload response status: ${response.statusCode}');
      print('🔍 Upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['imageUrl'] as String;
        print('✅ Image uploaded successfully!');
        print('✅ Server response: $data');
        print('✅ Image URL: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Upload failed with status: ${response.statusCode}');
        print('❌ Response body: ${response.body}');

        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Error al subir imagen');
        } catch (e) {
          throw Exception('Error del servidor: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Upload exception: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Error de conexión: ${e.toString()}');
      }
    }
  }

  // Eliminar imagen del servidor
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extraer filename de la URL
      final uri = Uri.parse(imageUrl);
      final filename = uri.pathSegments.last;

      final headers = await _getHeaders();
      final deleteUri = Uri.parse('${ApiConfig.upload}/image/$filename');

      print('🔍 Deleting image: $deleteUri');

      final response = await http
          .delete(deleteUri, headers: headers)
          .timeout(Duration(milliseconds: ApiConfig.timeout));

      print('🔍 Delete response status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Verificar si una URL es una imagen local o del servidor
  static bool isServerImage(String imageUrl) {
    if (imageUrl.isEmpty) return false;
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  // Verificar si una URL es una imagen local del dispositivo
  static bool isLocalImage(String imageUrl) {
    if (imageUrl.isEmpty) return false;
    return imageUrl.startsWith('file://') || imageUrl.startsWith('/');
  }

  // Construir URL completa para imágenes del servidor
  static String buildServerImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';

    // Si ya es una URL completa, devolverla tal como está
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Si es una ruta relativa, construir URL completa
    if (imagePath.startsWith('/uploads/')) {
      return '${ApiConfig.serverBaseUrl}$imagePath';
    }

    // Si solo es el nombre del archivo
    return '${ApiConfig.serverBaseUrl}/uploads/$imagePath';
  }
}
