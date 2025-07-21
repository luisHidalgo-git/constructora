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

      // Generar un ID de sesión único
      _sessionId = await TVAuthService.createTVSession();

      print('🔍 Created TV session: $_sessionId');

      // Crear datos del QR que incluyen información para el login
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

      print('🔍 Generated QR data for TV login: $_qrData');
      print('🔍 Session ID: $_sessionId');
    } catch (e) {
      print('❌ Error generating QR data: $e');
      _showError('Error generando código QR: ${e.toString()}');
    }
  }

  void _startPollingForAuth() {
    _pollingAttempts = 0;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _pollingAttempts++;

      if (!mounted || _isConnected || _sessionId == null) {
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
          print('🔄 Auto-regenerating QR after $_regenerationIntervalMinutes minutes');
          _regenerateQR();
        }
      },
    );
  }

  Future<void> _checkForAuth() async {
    if (_sessionId == null) return;

    try {
      print(
        '🔍 Checking auth status for session: $_sessionId (attempt $_pollingAttempts)',
      );

      final sessionStatus = await TVAuthService.checkTVSessionStatus(
        _sessionId!,
      );

      // Verificar si la sesión está autenticada con datos de usuario reales
      if (sessionStatus != null && 
          sessionStatus['status'] == 'authenticated' &&
          sessionStatus['userData'] != null) {
        print('✅ Session authenticated, proceeding to dashboard...');
        print('✅ User data received: ${sessionStatus['userData']['name']}');
        _pollingTimer?.cancel();
        _regenerationTimer?.cancel();

        setState(() {
          _isConnected = true;
        });

        // Mostrar mensaje de éxito
        _showSuccessMessage();

        // Esperar un momento antes de navegar
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          // Limpiar la sesión después de usarla
          await TVAuthService.clearTVSession(_sessionId!);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TVDashboardScreen()),
          );
        }
      } else if (sessionStatus != null && sessionStatus['status'] == 'authenticated') {
        // Si está autenticada pero sin datos de usuario, esperar más
        print('⚠️ Session authenticated but no user data yet, waiting...');
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
    }
  }

  void _showSuccessMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('¡Conexión exitosa! Redirigiendo al dashboard...'),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
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
    setState(() {
      _isConnected = false;
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

              // QR Code Container - Más grande
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
              if (_isConnected) ...[
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        '¡Conexión Exitosa!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'Esperando conexión desde móvil...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
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
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGray,
              ),
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