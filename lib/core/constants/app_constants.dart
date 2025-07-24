class AppConstants {
  // API Configuration
  static const String defaultApiUrl = 'https://constructora-production-beec.up.railway.app/api';
  static const int defaultTimeout = 45000;
  static const String jwtSecret = 'constructora_jwt_secret_2024';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // Image Configuration
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  static const String defaultProjectImage = 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  
  // QR Code Configuration
  static const int qrCodeExpirationMinutes = 2;
  static const int syncPollingIntervalSeconds = 2;
  static const int dataRefreshIntervalSeconds = 30;
  
  // Project Status Options
  static const List<String> projectStatusOptions = [
    'Activo',
    'Pausado',
    'Completado',
    'Cancelado',
  ];
  
  // Activity Types
  static const List<String> activityTypes = [
    'installation',
    'review',
    'completion',
    'inspection',
    'maintenance',
    'other',
  ];
  
  // User Roles
  static const List<String> userRoles = [
    'admin',
    'supervisor',
    'worker',
  ];
}