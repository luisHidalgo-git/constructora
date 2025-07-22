import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
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
      'Accept': '*/*',
      'Connection': 'keep-alive',
      // No incluir Content-Type para multipart, se establece automáticamente
    };
  }

  // Subir imagen al servidor automáticamente con reintentos mejorados
  static Future<String> uploadImageAutomatically(String imagePath) async {
    int maxRetries = 5;
    int currentRetry = 0;
    
    while (currentRetry < maxRetries) {
      try {
        print('🔍 Starting image upload attempt ${currentRetry + 1}/$maxRetries...');
        print('🔍 Image path: $imagePath');
        
        // Verificar que el archivo local existe
        final file = File(imagePath);
        if (!file.existsSync()) {
          throw Exception('El archivo de imagen no existe: $imagePath');
        }
        
        final fileSize = file.lengthSync();
        print('✅ Image file exists, size: $fileSize bytes');
        
        // Verificar tamaño del archivo (máximo 5MB para mejor rendimiento)
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('La imagen es demasiado grande. Máximo 5MB permitido.');
        }
        
        final headers = await _getMultipartHeaders();
        final uri = Uri.parse('${ApiConfig.upload}/image');
        
        print('🔍 Uploading image to: $uri');
        print('🔍 Headers: ${headers.keys.toList()}');
        
        // Crear request multipart con configuración mejorada
        var request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);
        
        // Generar nombre único para el archivo
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = path.extension(imagePath).toLowerCase();
        final filename = 'project_${timestamp}${extension.isEmpty ? '.jpg' : extension}';
        
        print('🔍 Uploading with filename: $filename');
        
        // Determinar el tipo MIME correcto
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
          filename: filename,
          contentType: mediaType,
        );
        request.files.add(multipartFile);
        
        print('🔍 Sending multipart request to server...');
        
        // Enviar request con timeout optimizado
        var streamedResponse = await request.send().timeout(
          Duration(seconds: 120 + (currentRetry * 30)), // Timeout progresivo
        );
        var response = await http.Response.fromStream(streamedResponse);
        
        print('🔍 Upload response status: ${response.statusCode}');
        print('🔍 Upload response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final imageUrl = data['imageUrl'] as String;
          print('✅ Image uploaded successfully to server!');
          print('✅ Server response: $data');
          print('✅ Image URL: $imageUrl');
          
          // Verificar que la URL es válida
          if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
            // Verificar que la imagen realmente existe en el servidor
            final imageExists = await checkImageExists(imageUrl);
            if (imageExists) {
              print('✅ Image verified on server: $imageUrl');
            return imageUrl;
            } else {
              throw Exception('La imagen no se pudo verificar en el servidor');
            }
          } else {
            throw Exception('URL de imagen inválida recibida del servidor');
          }
        } else {
          print('❌ Upload failed with status: ${response.statusCode}');
          print('❌ Response body: ${response.body}');
          
          // Si es un error del servidor, intentar de nuevo
          if (response.statusCode >= 500 && currentRetry < maxRetries - 1) {
            currentRetry++;
            print('🔄 Retrying upload due to server error... (${currentRetry}/${maxRetries})');
            await Future.delayed(Duration(seconds: currentRetry * 3));
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
        if ((e.toString().contains('Exception') || 
             e.toString().contains('SocketException') ||
             e.toString().contains('TimeoutException') ||
             e.toString().contains('Connection') ||
             e.toString().contains('Network') ||
             e.toString().contains('HandshakeException')) && 
            currentRetry < maxRetries - 1) {
          currentRetry++;
          print('🔄 Retrying upload due to connectivity error... (${currentRetry}/${maxRetries})');
          await Future.delayed(Duration(seconds: currentRetry * 5));
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
    
    throw Exception('CRÍTICO: No se pudo subir la imagen al servidor después de $maxRetries intentos. La imagen debe estar en el servidor para funcionar en múltiples dispositivos.');
  }

  // Método legacy para compatibilidad
  static Future<String> uploadImage(String imagePath) async {
    return await uploadImageAutomatically(imagePath);
  }

  // Procesar imagen automáticamente (decidir si subir o usar existente)
  static Future<String> processImageForProject(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      print('⚠️ No image path provided, using default image');
      return 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800';
    }
    
    if (isServerImage(imagePath)) {
      print('✅ Image is already on server: $imagePath');
      // Verificar que la imagen del servidor realmente existe
      final exists = await checkImageExists(imagePath);
      if (exists) {
      return imagePath;
      } else {
        print('❌ Server image does not exist, using default');
        return 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800';
      }
    }
    
    // Si es imagen local, DEBE subirse al servidor
    if (isLocalImage(imagePath)) {
      print('🔍 Local image detected, MUST upload to server for multi-device support...');
      return await uploadImageAutomatically(imagePath);
    }
    
    // Si no es ni local ni del servidor, usar imagen por defecto
    print('⚠️ Unknown image type, using default image');
    return 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800';
  }

  // Eliminar imagen del servidor
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extraer filename de la URL del servidor
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


  // Verificar si una URL es una imagen del servidor
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
      
      print('🔍 Image exists check for $imageUrl: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking image existence: $e');
      return false;
    }
  }

  // Limpiar imágenes locales después de subir al servidor
  static Future<void> cleanupLocalImage(String localPath) async {
    try {
      if (isLocalImage(localPath)) {
        final file = File(localPath.startsWith('file://') 
            ? localPath.substring(7) 
            : localPath);
        if (file.existsSync()) {
          await file.delete();
          print('✅ Cleaned up local image: $localPath');
        }
      }
    } catch (e) {
      print('⚠️ Could not cleanup local image: $e');
      // No es crítico si no se puede limpiar
    }
  }

  // Método para obtener una imagen válida (con fallback)
  static Future<String> getValidImageUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800';
    }

    // Si es una URL del servidor, verificar que existe
    if (isServerImage(imageUrl)) {
      final exists = await checkImageExists(imageUrl);
      if (exists) {
        return imageUrl;
      } else {
        print('❌ Server image does not exist: $imageUrl');
        return 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800';
      }
    }

    // Si es una imagen local, verificar que existe
    if (isLocalImage(imageUrl)) {
      String filePath = imageUrl.startsWith('file://') 
          ? imageUrl.substring(7) 
          : imageUrl;
      File file = File(filePath);
      if (file.existsSync()) {
        return imageUrl;
      } else {
        print('❌ Local image does not exist: $imageUrl');
        return 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800';
      }
    }

    // Si no es ninguno de los anteriores, usar imagen por defecto
    return 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800';
  }
}