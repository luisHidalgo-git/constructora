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
      'Accept': 'application/json',
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

  // Subir imagen al servidor con reintentos
  static Future<String> uploadImage(String imagePath) async {
    int maxRetries = 3;
    int currentRetry = 0;
    
    while (currentRetry < maxRetries) {
      try {
        print('🔍 Starting image upload attempt ${currentRetry + 1}/$maxRetries...');
        print('🔍 Image path: $imagePath');
        
        // Verificar que el archivo existe
        final file = File(imagePath);
        if (!file.existsSync()) {
          throw Exception('El archivo de imagen no existe: $imagePath');
        }
        
        final fileSize = file.lengthSync();
        print('✅ Image file exists, size: $fileSize bytes');
        
        // Verificar tamaño del archivo (máximo 5MB)
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('La imagen es demasiado grande. Máximo 5MB permitido.');
        }
        
        final headers = await _getMultipartHeaders();
        final uri = Uri.parse('${ApiConfig.upload}/image');
        
        print('🔍 Uploading image to: $uri');
        print('🔍 Headers: ${headers.keys.toList()}');
        
        // Crear request multipart
        var request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);
        
        // Agregar archivo con nombre único
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = imagePath.split('.').last.toLowerCase();
        final filename = 'project_image_${timestamp}.$extension';
        
        var multipartFile = await http.MultipartFile.fromPath(
          'image', 
          imagePath,
          filename: filename,
        );
        request.files.add(multipartFile);
        
        print('🔍 Sending multipart request with filename: $filename');
        
        // Enviar request con timeout extendido
        var streamedResponse = await request.send().timeout(
          const Duration(seconds: 60), // Timeout más largo para subida
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
          
          // Verificar que la URL es válida
          if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
            return imageUrl;
          } else {
            throw Exception('URL de imagen inválida recibida del servidor');
          }
        } else {
          print('❌ Upload failed with status: ${response.statusCode}');
          print('❌ Response body: ${response.body}');
          
          // Si es un error del servidor, intentar de nuevo
          if (response.statusCode >= 500 && currentRetry < maxRetries - 1) {
            currentRetry++;
            print('🔄 Retrying upload due to server error...');
            await Future.delayed(Duration(seconds: currentRetry * 2));
            continue;
          }
          
          try {
            final error = jsonDecode(response.body);
            throw Exception(error['message'] ?? 'Error al subir imagen');
          } catch (e) {
            throw Exception('Error del servidor: ${response.statusCode}');
          }
        }
        
      } catch (e) {
        print('❌ Upload exception (attempt ${currentRetry + 1}): $e');
        
        // Si es un error de conectividad y no es el último intento, reintentar
        if ((e.toString().contains('ClientException') || 
             e.toString().contains('SocketException') ||
             e.toString().contains('TimeoutException')) && 
            currentRetry < maxRetries - 1) {
          currentRetry++;
          print('🔄 Retrying upload due to connectivity error...');
          await Future.delayed(Duration(seconds: currentRetry * 3));
          continue;
        }
        
        // Si es el último intento o un error no recuperable, lanzar excepción
        if (e is Exception) {
          rethrow;
        } else {
          throw Exception('Error de conexión: ${e.toString()}');
        }
      }
    }
    
    throw Exception('No se pudo subir la imagen después de $maxRetries intentos');
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
      
      final response = await http.delete(
        deleteUri,
        headers: headers,
      ).timeout(Duration(milliseconds: ApiConfig.timeout));
      
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

  // Verificar si una imagen del servidor existe
  static Future<bool> checkImageExists(String imageUrl) async {
    try {
      if (!isServerImage(imageUrl)) return false;
      
      final response = await http.head(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking image existence: $e');
      return false;
    }
  }
}