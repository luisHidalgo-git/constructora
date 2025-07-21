import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:async';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/auth_service.dart';
import '../services/tv_auth_service.dart';
import 'tv_dashboard_screen.dart';

class TVQRLoginScreen extends StatefulWidget {
  const TVQRLoginScreen({super.key});

  @override
  State<TVQRLoginScreen> createState() => _TVQRLoginScreenState();
}

class _TVQRLoginScreenState extends State<TVQRLoginScreen> {
  String? _qrData;
  String? _sessionId;
  Timer? _pollingTimer;
  Timer? _regenerationTimer;
  bool _isConnected = false;
  bool _isAuthenticating = false;
  int _pollingAttempts = 0;
  static const int _maxPollingAttempts = 150; // 5 minutos máximo
  static const int _regenerationIntervalMinutes = 3; // Regenerar cada 3 minutos

  @override
  void initState() {
    super.initState();
    _generateQRData();
    _startPollingForAuth();
    _startRegenerationTimer();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _regenerationTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQRData() async {
    try {
      print('🔍 Generating new QR data...');
      // Limpiar sesiones expiradas primero
      await TVAuthService.cleanupExpiredSessions();

      // Crear sesión en el backend
      _sessionId = await TVAuthService.createTVSession();

      print('🔍 Created TV session: $_sessionId');

      // Obtener datos del QR del backend
      final qrData = await TVAuthService.getTVQRData();
      if (qrData != null) {
        setState(() {
          _qrData = qrData;
          _pollingAttempts = 0; // Reset counter
        });

        print('🔍 Generated QR data from backend: $_qrData');
        print('🔍 Session ID: $_sessionId');
      } else {
        // Fallback: crear QR data localmente
        final qrLoginData = {
          'type': 'tv_login',
          'sessionId': _sessionId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'appName': 'Avanze360',
          'version': '1.0.0',
        };

        setState(() {
          _qrData = jsonEncode(qrLoginData);
          _pollingAttempts = 0; // Reset counter
        });

        print('🔍 Generated QR data locally (fallback): $_qrData');
        print('🔍 Session ID: $_sessionId');
      }
    } catch (e) {
      print('❌ Error generating QR data: $e');
      _showError('Error generando código QR: ${e.toString()}');
    }
  }

  void _startPollingForAuth() {
    _pollingAttempts = 0;
    _isAuthenticating = false;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      _pollingAttempts++;

      if (!mounted || _isConnected || _sessionId == null || _isAuthenticating) {
        timer.cancel();
        return;
      }

      if (_pollingAttempts > _maxPollingAttempts) {
        print('❌ Max polling attempts reached, regenerating session...');
        timer.cancel();
        _regenerateQR();
        return;
      }

      _checkForAuth();
    });
  }

  void _startRegenerationTimer() {
    _regenerationTimer?.cancel();
    _regenerationTimer = Timer.periodic(
      Duration(minutes: _regenerationIntervalMinutes),
      (timer) {
        if (!_isConnected && mounted) {
          print(
            '🔄 Auto-regenerating QR after $_regenerationIntervalMinutes minutes',
          );
          _regenerateQR();
        }
      },
    );
  }

  Future<void> _checkForAuth() async {
    if (_sessionId == null) return;

    try {
      print(
        '🔍 TV: Checking auth status for session: $_sessionId (attempt $_pollingAttempts)',
      );

      final sessionStatus = await TVAuthService.checkTVSessionStatus(
        _sessionId!,
      );

      if (sessionStatus == null) {
        print('❌ TV: Session not found in backend, may have expired');
        if (_pollingAttempts > 30) {
          print('🔄 TV: Session not found, regenerating...');
          _pollingTimer?.cancel();
          _regenerateQR();
        }
        return;
      }

      print('🔍 TV: Session status: ${sessionStatus['status']}');

      if (sessionStatus['status'] == 'expired') {
        print('❌ TV: Session expired, regenerating...');
        _pollingTimer?.cancel();
        _regenerateQR();
        return;
      }

      if (sessionStatus['status'] == 'authenticated') {
        final userData = sessionStatus['userData'];

        if (userData != null && userData['name'] != null) {
          print(
            '✅ TV: Session authenticated with user data: ${userData['name']}',
          );
          await _handleSuccessfulAuth(userData);
        } else {
          print('⚠️ TV: Session authenticated but waiting for user data...');
          // Continuar polling por un poco más para obtener datos de usuario
          if (_pollingAttempts > 60) {
            print('❌ TV: Timeout waiting for user data, regenerating...');
            _pollingTimer?.cancel();
            _regenerateQR();
          }
        }
      } else if (sessionStatus['status'] == 'waiting') {
        print('🔍 TV: Session still waiting for authentication...');
        // Continuar polling
      }
    } catch (e) {
      print('❌ TV: Error checking auth status: $e');
      if (_pollingAttempts > 60) {
        print('🔄 TV: Too many errors, regenerating session...');
        _pollingTimer?.cancel();
        _regenerateQR();
      }
    }
  }

  Future<void> _handleSuccessfulAuth(Map<String, dynamic> userData) async {
    if (_isAuthenticating || _isConnected) return;

    setState(() {
      _isAuthenticating = true;
    });

    _pollingTimer?.cancel();
    _regenerationTimer?.cancel();

    try {
      print('✅ TV: Processing successful authentication...');

      // Guardar datos de usuario para la TV
      await TVAuthService.clearTVUserData(); // Limpiar datos anteriores
      // Los datos de usuario ya se guardan automáticamente en el servicio de autenticación
      // cuando se autentica la sesión desde el móvil

      setState(() {
        _isConnected = true;
      });

      // Mostrar mensaje de éxito
      _showSuccessMessage(userData['name']);

      // Esperar un momento antes de navegar
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Limpiar la sesión después de usarla
        if (_sessionId != null) {
          await TVAuthService.clearTVSession(_sessionId!);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TVDashboardScreen()),
        );
      }
    } catch (e) {
      print('❌ TV: Error handling successful auth: $e');
      setState(() {
        _isAuthenticating = false;
        _isConnected = false;
      });
      _showError('Error procesando autenticación: ${e.toString()}');
      _regenerateQR();
    }
  }

  void _showSuccessMessage(String userName) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('¡Bienvenido $userName! Cargando dashboard...'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _regenerateQR() {
    if (_isAuthenticating) return;

    setState(() {
      _isConnected = false;
      _isAuthenticating = false;
      _qrData = null;
      _sessionId = null;
      _pollingAttempts = 0;
    });
    _pollingTimer?.cancel();
    _generateQRData();
    _startPollingForAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.goBack ||
                event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                margin: const EdgeInsets.only(bottom: 60),
                child: Column(
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Avanze',
                            style: TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -2,
                            ),
                          ),
                          TextSpan(
                            text: '360',
                            style: TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: -2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Escanea el código QR desde tu\naplicación móvil para poder acceder al\ndashboard de avance360',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // QR Code Container
              Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: _buildQRContent(),
              ),

              const SizedBox(height: 60),

              // Status
              if (_isConnected || _isAuthenticating) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isAuthenticating && !_isConnected) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF10B981),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Procesando autenticación...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '¡Conexión Exitosa!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                Column(
                  children: [
                    const Text(
                      'Esperando conexión desde móvil...',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Intento ${_pollingAttempts} de $_maxPollingAttempts',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRContent() {
    if (_isConnected) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 80),
            SizedBox(height: 20),
            Text(
              '¡Conectado!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    }

    if (_qrData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 4),
            SizedBox(height: 20),
            Text(
              'Generando código...',
              style: TextStyle(fontSize: 16, color: AppColors.textGray),
            ),
          ],
        ),
      );
    }

    // QR Code real usando qr_flutter - Más grande
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: QrImageView(
              data: _qrData!,
              version: QrVersions.auto,
              size: 260,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'QR Login Code',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
