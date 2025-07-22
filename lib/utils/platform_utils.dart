import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool isTV() {
    if (kIsWeb) return false;
    
    // En Android, detectamos si es TV verificando las características del sistema
    // Para propósitos de desarrollo, también podemos usar el tamaño de pantalla
    if (Platform.isAndroid) {
      // Por ahora, detectamos TV por tamaño de pantalla grande
      // En producción, esto se haría con platform channels
      return false;
    }
    
    return false;
  }

  // Método para forzar modo TV (útil para testing)
  static bool isTVMode() {
    // Puedes cambiar esto a true para probar el modo TV
    return false;
  }
  
  static bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
  }
  
  static bool isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}