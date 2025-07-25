import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';
import '../../services/image_service.dart';

class ImageUtils {
  static ImageProvider? buildImageProvider(String imageUrl) {
    try {
      if (imageUrl.isEmpty) {
        return null;
      }

      print('🔍 ImageUtils - Building image provider for: $imageUrl');

      // Si es una URL de internet
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        print('✅ ImageUtils - Using NetworkImage for: $imageUrl');
        return NetworkImage(imageUrl);
      }

      // Si es un archivo local
      if (imageUrl.startsWith('file://') || imageUrl.startsWith('/')) {
        String filePath = imageUrl.startsWith('file://')
            ? imageUrl.substring(7)
            : imageUrl;
        File file = File(filePath);
        if (file.existsSync()) {
          print('✅ ImageUtils - Using FileImage for: $filePath');
          return FileImage(file);
        } else {
          print('❌ ImageUtils - Local file does not exist: $filePath');
          // Si el archivo local no existe, intentar construir URL del servidor
          final serverUrl = ImageService.buildServerImageUrl(
            '/uploads/${path.basename(filePath)}',
          );
          print('🔄 ImageUtils - Trying server URL: $serverUrl');
          return NetworkImage(serverUrl);
        }
      }

      // Si es una ruta del servidor sin dominio, construir URL completa
      if (imageUrl.startsWith('/uploads/')) {
        final fullUrl = ImageService.buildServerImageUrl(imageUrl);
        print('✅ ImageUtils - Built server URL: $fullUrl');
        return NetworkImage(fullUrl);
      }

      // Si parece ser un nombre de archivo, intentar construir URL del servidor
      if (!imageUrl.contains('/') &&
          (imageUrl.contains('.jpg') ||
              imageUrl.contains('.png') ||
              imageUrl.contains('.jpeg'))) {
        final fullUrl = ImageService.buildServerImageUrl('/uploads/$imageUrl');
        print('✅ ImageUtils - Built server URL from filename: $fullUrl');
        return NetworkImage(fullUrl);
      }

      print('❌ ImageUtils - Could not determine image provider type for: $imageUrl');
      return NetworkImage(AppConstants.defaultProjectImage);
    } catch (e) {
      print('❌ ImageUtils - Error loading image: $e');
      return NetworkImage(AppConstants.defaultProjectImage);
    }
  }
  
  static Widget buildImageContainer({
    required String imageUrl,
    required double width,
    required double height,
    BorderRadius? borderRadius,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    bool showOverlay = false,
    String? overlayText,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        image: buildImageProvider(imageUrl) != null
            ? DecorationImage(
                image: buildImageProvider(imageUrl)!,
                fit: fit,
              )
            : null,
        color: buildImageProvider(imageUrl) == null
            ? Colors.grey[300]
            : null,
      ),
      child: Stack(
        children: [
          if (buildImageProvider(imageUrl) == null)
            Center(
              child: placeholder ?? const Icon(
                Icons.image_outlined,
                color: Colors.grey,
                size: 30,
              ),
            ),
          if (showOverlay && overlayText != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: borderRadius?.bottomLeft ?? const Radius.circular(12),
                    bottomRight: borderRadius?.bottomRight ?? const Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Text(
                  overlayText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}