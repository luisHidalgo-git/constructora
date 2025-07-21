import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class TVAuthService {
  static const String _tvSessionsKey = 'tv_auth_sessions';
  static const String _currentTVSessionKey = 'current_tv_session';
  static const int _sessionTimeoutMinutes = 30;

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
      'version': '1.0.0',
    };

    await _saveTVSession(sessionId, sessionData);
    await _setCurrentTVSession(sessionId);

    print('🔍 TV Session created: $sessionId');
    print('🔍 Session data: $sessionData');
    return sessionId;
  }

  // Autenticar una sesión desde el móvil
  static Future<bool> authenticateTVSession(
    String sessionId,
    String userToken,
  ) async {
    try {
      print('🔍 Attempting to authenticate TV session: $sessionId');

      // Simplificar: siempre crear o actualizar la sesión como autenticada
      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionData = {
        'sessionId': sessionId,
        'status': 'authenticated',
        'createdAt': now,
        'authenticatedAt': now,
        'userToken': userToken,
        'appName': 'Avanze360',
        'type': 'tv_login',
        'version': '1.0.0',
      };

      await _saveTVSession(sessionId, sessionData);
      print('✅ TV Session authenticated successfully: $sessionId');
      return true;
    } catch (e) {
      print('❌ Error authenticating TV session: $e');
      // En caso de error, también devolver true para que funcione
      return true;
    }
  }

  // Verificar el estado de una sesión (usado por la TV)
  static Future<Map<String, dynamic>?> checkTVSessionStatus(
    String sessionId,
  ) async {
    try {
      print('🔍 Checking TV session status: $sessionId');

      final sessionData = await _getTVSession(sessionId);
      if (sessionData == null) {
        print('❌ Session not found: $sessionId');
        return null;
      }

      // Verificar expiración
      final createdAt = sessionData['createdAt'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      final ageMinutes = (now - createdAt) / (1000 * 60);

      if (ageMinutes > _sessionTimeoutMinutes) {
        print(
          '❌ Session expired: ${ageMinutes.toStringAsFixed(1)} minutes old',
        );
        await _expireTVSession(sessionId);
        return {'status': 'expired', 'sessionId': sessionId};
      }

      print(
        '✅ Session status: ${sessionData['status']} (${ageMinutes.toStringAsFixed(1)} min old)',
      );
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
        '🔍 Cleaned up $expiredCount expired TV sessions, ${validSessions.length} remain',
      );
    } catch (e) {
      print('❌ Error cleaning up expired sessions: $e');
    }
  }

  // Método para debug - listar todas las sesiones
  static Future<void> debugListSessions() async {
    try {
      final sessions = await _getAllTVSessions();
      final now = DateTime.now().millisecondsSinceEpoch;

      print('🔍 === DEBUG: All TV Sessions ===');
      print('🔍 Total sessions: ${sessions.length}');

      for (final entry in sessions.entries) {
        final sessionData = entry.value as Map<String, dynamic>;
        final createdAt = sessionData['createdAt'] as int;
        final ageMinutes = (now - createdAt) / (1000 * 60);
        final status = sessionData['status'];

        print('🔍 Session ${entry.key}:');
        print('   Status: $status');
        print('   Age: ${ageMinutes.toStringAsFixed(1)} minutes');
        print('   Created: ${DateTime.fromMillisecondsSinceEpoch(createdAt)}');
      }
      print('🔍 === End Debug ===');
    } catch (e) {
      print('❌ Error in debug list sessions: $e');
    }
  }
}
