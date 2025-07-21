import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class TVAuthService {
  static const String _tvSessionsKey = 'tv_auth_sessions';
  static const String _currentTVSessionKey = 'current_tv_session';

  // Simular un "servidor" local usando SharedPreferences
  // En una implementación real, esto sería un WebSocket o API

  // Crear una nueva sesión de TV
  static Future<String> createTVSession() async {
    final sessionId = _generateSessionId();
    final sessionData = {
      'sessionId': sessionId,
      'status': 'waiting', // waiting, authenticated, expired
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'authenticatedAt': null,
      'userToken': null,
      'appName': 'Avanze360',
      'type': 'tv_login',
    };

    await _saveTVSession(sessionId, sessionData);
    await _setCurrentTVSession(sessionId);

    print('🔍 TV Session created: $sessionId');
    return sessionId;
  }

  // Autenticar una sesión desde el móvil
  static Future<bool> authenticateTVSession(
    String sessionId,
    String userToken,
  ) async {
    try {
      final sessionData = await _getTVSession(sessionId);
      if (sessionData == null) {
        print('❌ TV Session not found: $sessionId');
        return false;
      }

      if (sessionData['status'] != 'waiting') {
        print('❌ TV Session not in waiting state: ${sessionData['status']}');
        return false;
      }

      // Verificar que la sesión no haya expirado (30 minutos)
      final createdAt = sessionData['createdAt'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - createdAt > 30 * 60 * 1000) {
        print('❌ TV Session expired');
        await _expireTVSession(sessionId);
        return false;
      }

      // Autenticar la sesión
      sessionData['status'] = 'authenticated';
      sessionData['authenticatedAt'] = now;
      sessionData['userToken'] = userToken;

      await _saveTVSession(sessionId, sessionData);
      print('✅ TV Session authenticated: $sessionId');
      return true;
    } catch (e) {
      print('❌ Error authenticating TV session: $e');
      return false;
    }
  }

  // Verificar el estado de una sesión (usado por la TV)
  static Future<Map<String, dynamic>?> checkTVSessionStatus(
    String sessionId,
  ) async {
    try {
      final sessionData = await _getTVSession(sessionId);
      if (sessionData == null) return null;

      // Verificar expiración
      final createdAt = sessionData['createdAt'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - createdAt > 30 * 60 * 1000) {
        await _expireTVSession(sessionId);
        return {'status': 'expired'};
      }

      return sessionData;
    } catch (e) {
      print('❌ Error checking TV session status: $e');
      return null;
    }
  }

  // Limpiar sesión después de usar
  static Future<void> clearTVSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await _getAllTVSessions();
      sessions.remove(sessionId);
      await prefs.setString(_tvSessionsKey, jsonEncode(sessions));

      final currentSession = await _getCurrentTVSession();
      if (currentSession == sessionId) {
        await prefs.remove(_currentTVSessionKey);
      }

      print('🔍 TV Session cleared: $sessionId');
    } catch (e) {
      print('❌ Error clearing TV session: $e');
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

  // Métodos privados
  static String _generateSessionId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
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
    } catch (e) {
      print('❌ Error saving TV session: $e');
    }
  }

  static Future<Map<String, dynamic>?> _getTVSession(String sessionId) async {
    try {
      final sessions = await _getAllTVSessions();
      return sessions[sessionId];
    } catch (e) {
      print('❌ Error getting TV session: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> _getAllTVSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_tvSessionsKey);
      if (sessionsJson == null) return {};
      return Map<String, dynamic>.from(jsonDecode(sessionsJson));
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
      }
    } catch (e) {
      print('❌ Error expiring TV session: $e');
    }
  }

  // Limpiar sesiones expiradas
  static Future<void> cleanupExpiredSessions() async {
    try {
      final sessions = await _getAllTVSessions();
      final now = DateTime.now().millisecondsSinceEpoch;
      final validSessions = <String, dynamic>{};

      for (final entry in sessions.entries) {
        final sessionData = entry.value as Map<String, dynamic>;
        final createdAt = sessionData['createdAt'] as int;

        // Mantener sesiones que no han expirado (30 minutos)
        if (now - createdAt <= 30 * 60 * 1000) {
          validSessions[entry.key] = sessionData;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tvSessionsKey, jsonEncode(validSessions));

      print('🔍 Cleaned up expired TV sessions');
    } catch (e) {
      print('❌ Error cleaning up expired sessions: $e');
    }
  }
}
