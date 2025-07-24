import 'package:flutter/material.dart';

class ColorUtils {
  static Color getProgressColor(double progress) {
    if (progress >= 0.7) {
      return const Color(0xFF10B981); // Green
    } else if (progress >= 0.4) {
      return const Color(0xFF3B82F6); // Blue
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }
  
  static Color getStatusColor(String status) {
    switch (status) {
      case 'Activo':
        return const Color(0xFF10B981);
      case 'Pausado':
        return const Color(0xFFFF9500);
      case 'Completado':
        return const Color(0xFF3B82F6);
      case 'Cancelado':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10B981);
    }
  }
  
  static Color getIndicatorColor(double value) {
    if (value >= 0.8) {
      return const Color(0xFF10B981);
    } else if (value >= 0.6) {
      return const Color(0xFF3B82F6);
    } else if (value >= 0.4) {
      return const Color(0xFFFF9500);
    } else {
      return const Color(0xFFEF4444);
    }
  }
  
  static Color getIndicatorColorByName(String indicator) {
    switch (indicator) {
      case 'Calidad':
        return const Color(0xFF10B981);
      case 'Tiempo':
        return const Color(0xFFFF9500);
      case 'Presupuesto':
        return const Color(0xFF6366F1);
      case 'Satisfacción':
        return const Color(0xFF8B5CF6);
      case 'Instalaciones':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6366F1);
    }
  }
  
  static Color getUpdateTypeColor(String updateType) {
    switch (updateType) {
      case 'Actualización':
        return const Color(0xFF8B5CF6);
      case 'Inicio':
        return const Color(0xFFFF9500);
      default:
        return const Color(0xFF6366F1);
    }
  }
}