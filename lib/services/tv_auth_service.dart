import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class TVAuthService {
  static const String _tvSessionsKey = 'tv_auth_sessions';
  static const String _currentTVSessionKey = 'current_tv_session';
  static const String _tvUserDataKey = 'tv_user_data';
  static const int _sessionTimeoutMinutes = 30;

  // Crear una nueva sesión de TV usando el backend
  static Future<String> createTVSession() async {
    try {
      print('🔍 Creating TV session via backend...');
      
      final response = await http.post(
        Uri.parse(ApiConfig.createTVSession),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'ConstructoraTV/1.0',
        },
      ).timeout(Duration(milliseconds: ApiConfig.timeout));

      print('🔍 Create session response status: ${response.statusCode}');
      print('🔍 Create session response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final sessionId = data['sessionId'];
        final qrData = data['qrData'];
        
        // Guardar localmente para referencia
        await _setCurrentTVSession(sessionId);
        
        // Guardar los datos del QR localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tv_qr_data', qrData);
        
        print('✅ TV Session created via backend: $sessionId');
        return sessionId;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error creating TV session');
      }
    } catch (e) {
      print('❌ Error creating TV session via backend: $e');
      // Fallback al método local si falla el backend
      return await _createLocalTVSession();
    }
  }

  // Método de fallback para crear sesión local
  static Future<String> _createLocalTVSession() async {
    try {
      final sessionId = _generateSessionId();
      final sessionData = {
        'sessionId': sessionId,
        'status': 'waiting',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'authenticatedAt': null,
        'userToken': null,
        'userData': null,
        'appName': 'Avanze360',
        'type': 'tv_login',
        'version': '1.0.0',
      };

      await _saveTVSession(sessionId, sessionData);
      await _setCurrentTVSession(sessionId);

      print('🔍 TV Session created locally (fallback): $sessionId');
      return sessionId;
    } catch (e) {
      print('❌ Error creating local TV session: $e');
      throw Exception('Failed to create TV session: $e');
    }
  }

  // Obtener datos del QR para mostrar
  static Future<String?> getTVQRData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('tv_qr_data');
    } catch (e) {
      print('❌ Error getting TV QR data: $e');
      return null;
    }
  }

  // Autenticar una sesión desde el móvil usando el backend
  static Future<bool> authenticateTVSession(
    String sessionId,
    String userToken, {
    Map<String, dynamic>? userData,
  }) async {
    try {
      print('🔍 Mobile: Attempting to authenticate TV session via backend: $sessionId');
      print('🔍 Mobile: User data provided: ${userData != null}');
      if (userData != null) {
        print('🔍 Mobile: User details: ${userData['name']} - ${userData['email']}');
      }

      final response = await http.post(
        Uri.parse(ApiConfig.authenticateTVSession),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userToken',
          'User-Agent': 'ConstructoraApp/1.0',
        },
        body: jsonEncode({
          'sessionId': sessionId,
        }),
      ).timeout(Duration(milliseconds: ApiConfig.timeout));

      print('🔍 Mobile: Authenticate session response status: ${response.statusCode}');
      print('🔍 Mobile: Authenticate session response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Guardar datos de usuario para la TV localmente
        if (userData != null) {
          await _saveTVUserData(userData);
          print('✅ Mobile: User data saved for TV locally: ${userData['name']}');

          // Verificar que los datos se guardaron correctamente
          final savedData = await getTVUserData();
          if (savedData != null) {
            print('✅ Mobile: Verification: User data correctly saved: ${savedData['name']}');
          } else {
            print('❌ Mobile: Verification failed: User data not saved correctly');
            return false;
          }
        }

        print('✅ Mobile: TV Session authenticated successfully via backend: $sessionId');
        return true;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Mobile: Backend authentication failed: ${error['message']}');
        
        // Fallback al método local
        return await _authenticateLocalTVSession(sessionId, userToken, userData: userData);
      }
    } catch (e) {
      print('❌ Mobile: Error authenticating TV session via backend: $e');
      // Fallback al método local
      return await _authenticateLocalTVSession(sessionId, userToken, userData: userData);
    }
  }

  // Método de fallback para autenticación local
  static Future<bool> _authenticateLocalTVSession(
    String sessionId,
    String userToken, {
    Map<String, dynamic>? userData,
  }) async {
    try {
      print('🔍 Authenticating TV session locally (fallback): $sessionId');
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionData = {
        'sessionId': sessionId,
        'status': 'authenticated',
        'createdAt': now,
        'authenticatedAt': now,
        'userToken': userToken,
        'userData': userData,
        'appName': 'Avanze360',
        'type': 'tv_login',
        'version': '1.0.0',
      };

      await _saveTVSession(sessionId, sessionData);

      // Guardar datos de usuario para la TV
      if (userData != null) {
        await _saveTVUserData(userData);
        print('✅ User data saved for TV locally: ${userData['name']}');
      }

      print('✅ TV Session authenticated successfully locally: $sessionId');
      return true;
    } catch (e) {
      print('❌ Error authenticating TV session locally: $e');
      return false;
    }
  }

  // Autenticar sesión con datos reales del usuario autenticado
  static Future<bool> authenticateTVSessionWithRealUser(
    String sessionId,
  ) async {
    try {
      print('🔍 Mobile: Authenticating TV session with real user data...');

      // Obtener token y datos del usuario autenticado
      final userToken = await AuthService.getToken();
      final currentUser = await AuthService.getSavedUser();

      if (userToken == null || currentUser == null) {
        print('❌ Mobile: No authenticated user found');
        return false;
      }

      print('🔍 Mobile: Authenticating with user: ${currentUser.name}');
      print('🔍 Mobile: User email: ${currentUser.email}');
      print('🔍 Mobile: User position: ${currentUser.position}');

      // Usar los datos reales del usuario
      final userData = currentUser.toJson();
      
      print('🔍 Mobile: User data to send: ${userData.keys.toList()}');

      return await authenticateTVSession(
        sessionId,
        userToken,
        userData: userData,
      );
    } catch (e) {
      print('❌ Mobile: Error authenticating TV session with real user: $e');
      return false;
    }
  }

  // Verificar el estado de una sesión usando el backend
  static Future<Map<String, dynamic>?> checkTVSessionStatus(
    String sessionId,
  ) async {
    try {
      print('🔍 Checking TV session status via backend: $sessionId');

      final response = await http.get(
        Uri.parse(ApiConfig.tvSessionStatus(sessionId)),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'ConstructoraTV/1.0',
        },
      ).timeout(Duration(milliseconds: ApiConfig.timeout));

      print('🔍 Session status response status: ${response.statusCode}');
      print('🔍 Session status response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionData = data['sessionData'];
        
        // Verificar si hay datos de usuario en la sesión
        final userData = sessionData['userData'];
        if (sessionData['status'] == 'authenticated' && userData != null) {
          print('✅ Session authenticated with user data: ${userData['name']}');
        } else if (sessionData['status'] == 'authenticated') {
          print('⚠️ Session authenticated but no user data');
        }

        print('✅ Session status from backend: ${sessionData['status']}');
        return sessionData;
      } else if (response.statusCode == 404) {
        print('❌ Session not found in backend: $sessionId');
        // Fallback al método local
        return await _checkLocalTVSessionStatus(sessionId);
      } else {
        print('❌ Backend error checking session status: ${response.statusCode}');
        // Fallback al método local
        return await _checkLocalTVSessionStatus(sessionId);
      }
    } catch (e) {
      print('❌ Error checking TV session status via backend: $e');
      // Fallback al método local
      return await _checkLocalTVSessionStatus(sessionId);
    }
  }

  // Método de fallback para verificar estado local
  static Future<Map<String, dynamic>?> _checkLocalTVSessionStatus(
    String sessionId,
  ) async {
    try {
      print('🔍 Checking TV session status locally (fallback): $sessionId');

      final sessionData = await _getTVSession(sessionId);
      if (sessionData == null) {
        print('❌ Session not found locally: $sessionId');
        return null;
      }

      // Verificar expiración
      final createdAt = sessionData['createdAt'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      final ageMinutes = (now - createdAt) / (1000 * 60);

      if (ageMinutes > _sessionTimeoutMinutes) {
        print('❌ Session expired locally: ${ageMinutes.toStringAsFixed(1)} minutes old');
        await _expireTVSession(sessionId);
        return {'status': 'expired', 'sessionId': sessionId};
      }

      // Verificar si hay datos de usuario en la sesión
      final userData = sessionData['userData'];
      if (sessionData['status'] == 'authenticated' && userData != null) {
        print('✅ Session authenticated locally with user data: ${userData['name']}');
      } else if (sessionData['status'] == 'authenticated') {
        print('⚠️ Session authenticated locally but no user data');
      }

      print(
        '✅ Session status locally: ${sessionData['status']} (${ageMinutes.toStringAsFixed(1)} min old)',
      );
      return sessionData;
    } catch (e) {
      print('❌ Error checking TV session status locally: $e');
      return null;
    }
  }

  // Obtener datos de usuario para la TV
  static Future<Map<String, dynamic>?> getTVUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString(_tvUserDataKey);
      if (userDataJson != null) {
        final userData = jsonDecode(userDataJson);
        print('✅ Retrieved TV user data: ${userData['name']}');
        return userData;
      }
      print('❌ No TV user data found');
      return null;
    } catch (e) {
      print('❌ Error getting TV user data: $e');
      return null;
    }
  }

  // Limpiar sesión después de usar
  static Future<void> clearTVSession(String sessionId) async {
    try {
      print('🔍 Clearing TV session via backend: $sessionId');
      
      // Intentar limpiar en el backend primero
      try {
        final response = await http.delete(
          Uri.parse(ApiConfig.clearTVSession(sessionId)),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'ConstructoraTV/1.0',
          },
        ).timeout(Duration(milliseconds: ApiConfig.timeout));
        
        if (response.statusCode == 200) {
          print('✅ TV Session cleared from backend: $sessionId');
        } else {
          print('⚠️ Backend clear failed, clearing locally: ${response.statusCode}');
        }
      } catch (e) {
        print('⚠️ Backend clear error, clearing locally: $e');
      }
      
      // Limpiar localmente también
      final prefs = await SharedPreferences.getInstance();
      final sessions = await _getAllTVSessions();
      sessions.remove(sessionId);
      await prefs.setString(_tvSessionsKey, jsonEncode(sessions));

      final currentSession = await _getCurrentTVSession();
      if (currentSession == sessionId) {
        await prefs.remove(_currentTVSessionKey);
        await prefs.remove('tv_qr_data');
      }

      print('🔍 TV Session cleared: $sessionId');
    } catch (e) {
      print('❌ Error clearing TV session: $e');
    }
  }

  // Limpiar datos de usuario de TV
  static Future<void> clearTVUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tvUserDataKey);
      print('🔍 TV user data cleared');
    } catch (e) {
      print('❌ Error clearing TV user data: $e');
    }
  }

  // Obtener la sesión actual de TV
  static Future<String?> getCurrentTVSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentTVSessionKey);
    } catch (e) {
      print('❌ Error getting current TV session: $e');
      return null;
    }
  }

  // Validar formato de QR
  static bool isValidTVQRCode(String qrData) {
    try {
      print('🔍 Validating QR data: $qrData');
      final data = jsonDecode(qrData);
      final isValid =
          data['type'] == 'tv_login' &&
          data['sessionId'] != null &&
          data['appName'] == 'Avanze360';
      print('🔍 QR validation result: $isValid');
      return isValid;
    } catch (e) {
      print('❌ Error validating QR data: $e');
      return false;
    }
  }

  // Extraer sessionId del QR
  static String? extractSessionIdFromQR(String qrData) {
    try {
      final data = jsonDecode(qrData);
      if (isValidTVQRCode(qrData)) {
        final sessionId = data['sessionId'];
        print('🔍 Extracted session ID: $sessionId');
        return sessionId;
      }
      print('❌ QR data is not valid for session ID extraction');
      return null;
    } catch (e) {
      print('❌ Error extracting session ID: $e');
      return null;
    }
  }

  // Obtener todas las sesiones activas
  static Future<List<String>> getActiveSessions() async {
    try {
      final sessions = await _getAllTVSessions();
      final now = DateTime.now().millisecondsSinceEpoch;
      final activeSessions = <String>[];

      for (final entry in sessions.entries) {
        final sessionData = entry.value as Map<String, dynamic>;
        final createdAt = sessionData['createdAt'] as int;
        final ageMinutes = (now - createdAt) / (1000 * 60);

        if (ageMinutes <= _sessionTimeoutMinutes) {
          activeSessions.add(entry.key);
        }
      }

      print('🔍 Active sessions: ${activeSessions.length}');
      return activeSessions;
    } catch (e) {
      print('❌ Error getting active sessions: $e');
      return [];
    }
  }

  // Métodos privados
  static String _generateSessionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        16,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  static Future<void> _saveTVSession(
    String sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await _getAllTVSessions();
      sessions[sessionId] = sessionData;
      await prefs.setString(_tvSessionsKey, jsonEncode(sessions));
      print('🔍 Session saved: $sessionId');
    } catch (e) {
      print('❌ Error saving TV session: $e');
    }
  }

  static Future<void> _saveTVUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tvUserDataKey, jsonEncode(userData));
      print('🔍 TV user data saved: ${userData['name']}');
    } catch (e) {
      print('❌ Error saving TV user data: $e');
    }
  }

  static Future<Map<String, dynamic>?> _getTVSession(String sessionId) async {
    try {
      final sessions = await _getAllTVSessions();
      final sessionData = sessions[sessionId];
      if (sessionData != null) {
        print('🔍 Retrieved session: $sessionId');
      }
      return sessionData;
    } catch (e) {
      print('❌ Error getting TV session: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> _getAllTVSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_tvSessionsKey);
      if (sessionsJson == null) {
        print('🔍 No sessions found, returning empty map');
        return {};
      }
      final sessions = Map<String, dynamic>.from(jsonDecode(sessionsJson));
      print('🔍 Retrieved ${sessions.length} sessions from storage');
      return sessions;
    } catch (e) {
      print('❌ Error getting all TV sessions: $e');
      return {};
    }
  }

  static Future<String?> _getCurrentTVSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentTVSessionKey);
    } catch (e) {
      print('❌ Error getting current TV session: $e');
      return null;
    }
  }

  static Future<void> _setCurrentTVSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentTVSessionKey, sessionId);
      print('🔍 Set current TV session: $sessionId');
    } catch (e) {
      print('❌ Error setting current TV session: $e');
    }
  }

  static Future<void> _expireTVSession(String sessionId) async {
    try {
      final sessionData = await _getTVSession(sessionId);
      if (sessionData != null) {
        sessionData['status'] = 'expired';
        await _saveTVSession(sessionId, sessionData);
        print('🔍 Session expired: $sessionId');
      }
    } catch (e) {
      print('❌ Error expiring TV session: $e');
    }
  }

  // Limpiar sesiones expiradas
  static Future<void> cleanupExpiredSessions() async {
    try {
      print('🔍 Cleaning up expired sessions...');
      
      // Intentar limpiar en el backend primero
      try {
        final response = await http.post(
          Uri.parse(ApiConfig.cleanupExpiredSessions),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'ConstructoraTV/1.0',
          },
        ).timeout(Duration(milliseconds: ApiConfig.timeout));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ Backend cleanup completed: ${data['deletedCount']} sessions removed');
        } else {
          print('⚠️ Backend cleanup failed: ${response.statusCode}');
        }
      } catch (e) {
        print('⚠️ Backend cleanup error: $e');
      }
      
      // Limpiar localmente también
      final sessions = await _getAllTVSessions();
      final now = DateTime.now().millisecondsSinceEpoch;
      final validSessions = <String, dynamic>{};
      int expiredCount = 0;

      for (final entry in sessions.entries) {
        final sessionData = entry.value as Map<String, dynamic>;
        final createdAt = sessionData['createdAt'] as int;
        final ageMinutes = (now - createdAt) / (1000 * 60);

        // Mantener sesiones que no han expirado
        if (ageMinutes <= _sessionTimeoutMinutes) {
          validSessions[entry.key] = sessionData;
        } else {
          expiredCount++;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tvSessionsKey, jsonEncode(validSessions));

      print(
        '🔍 Cleaned up $expiredCount expired TV sessions locally, ${validSessions.length} remain',
      );
    } catch (e) {
      print('❌ Error cleaning up expired sessions: $e');
    }
  }
}
