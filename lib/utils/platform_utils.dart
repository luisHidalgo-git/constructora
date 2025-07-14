import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool isTV() {
    if (kIsWeb) return false;
    
    // En Android, detectamos si es TV verificando las características del sistema
    if (Platform.isAndroid) {
      // Esta es una aproximación - en un entorno real podrías usar
      // platform channels para verificar características específicas de TV
      return false; // Por ahora retornamos false, pero puedes cambiarlo para testing
    }
    
    return false;
  }
  
  static bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
  }
  
  static bool isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}