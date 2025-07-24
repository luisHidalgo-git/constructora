import '../constants/app_constants.dart';

class Validators {
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'El email es requerido';
    }
    
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Por favor ingresa un email válido';
    }
    
    return null;
  }
  
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (password.length < AppConstants.minPasswordLength) {
      return 'La contraseña debe tener al menos ${AppConstants.minPasswordLength} caracteres';
    }
    
    if (password.length > AppConstants.maxPasswordLength) {
      return 'La contraseña no puede exceder ${AppConstants.maxPasswordLength} caracteres';
    }
    
    return null;
  }
  
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    
    if (name.trim().length < AppConstants.minNameLength) {
      return 'El nombre debe tener al menos ${AppConstants.minNameLength} caracteres';
    }
    
    if (name.trim().length > AppConstants.maxNameLength) {
      return 'El nombre no puede exceder ${AppConstants.maxNameLength} caracteres';
    }
    
    return null;
  }
  
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }
  
  static String? validatePasswordConfirmation(String? password, String? confirmation) {
    if (password != confirmation) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
  
  static bool isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }
  
  static bool isValidImageExtension(String filename) {
    final extension = filename.toLowerCase();
    return AppConstants.allowedImageExtensions.any((ext) => extension.endsWith(ext));
  }
}