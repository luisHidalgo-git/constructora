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
  bool _isScanning = false;
  String? _qrData;
  String? _sessionId;
  Timer? _pollingTimer;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _generateQRData();
    _startPollingForAuth();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQRData() async {
    try {
      // Limpiar sesiones expiradas primero
      await TVAuthService.cleanupExpiredSessions();

      // Generar un ID de sesión único
      _sessionId = await TVAuthService.createTVSession();

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
      });

      print('🔍 Generated QR data for TV login: $_qrData');
      print('🔍 Session ID: $_sessionId');
    } catch (e) {
      print('❌ Error generating QR data: $e');
      _showError('Error generando código QR: ${e.toString()}');
    }
  }

  void _startPollingForAuth() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && !_isScanning && _sessionId != null && !_isConnected) {
        _checkForAuth();
      }
    });
  }

  Future<void> _checkForAuth() async {
    if (_sessionId == null) return;

    try {
      final sessionStatus = await TVAuthService.checkTVSessionStatus(
        _sessionId!,
      );

      if (sessionStatus == null) {
        print('❌ Session not found, regenerating...');
        await _generateQRData();
        return;
      }

      print('🔍 Session status: ${sessionStatus['status']}');

      if (sessionStatus['status'] == 'authenticated') {
        print('✅ Session authenticated, proceeding to dashboard...');
        _pollingTimer?.cancel();

        setState(() {
          _isScanning = true;
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
      } else if (sessionStatus['status'] == 'expired') {
        print('❌ Session expired, regenerating...');
        await _generateQRData();
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
    }
  }

  void _simulateQRScan() {
    if (_isScanning || _isConnected) return;

    setState(() {
      _isScanning = true;
    });

    Future.delayed(const Duration(seconds: 1), () async {
      try {
        if (_sessionId != null) {
          // Simular autenticación exitosa con token demo
          final demoToken =
              'demo_token_${DateTime.now().millisecondsSinceEpoch}';
          final success = await TVAuthService.authenticateTVSession(
            _sessionId!,
            demoToken,
          );

          if (success && mounted) {
            setState(() {
              _isConnected = true;
            });

            _showSuccessMessage();

            // Esperar antes de navegar
            await Future.delayed(const Duration(seconds: 2));

            if (mounted) {
              await TVAuthService.clearTVSession(_sessionId!);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TVDashboardScreen(),
                ),
              );
            }
            return;
          }
        }

        // Si falla, mostrar error
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
          _showError('Error en la simulación de escaneo');
        }
      } catch (e) {
        print('❌ Error in simulated login: $e');
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
          _showError('Error en la simulación: ${e.toString()}');
        }
      }
    });
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
      _isScanning = false;
      _isConnected = false;
      _qrData = null;
      _sessionId = null;
    });
    _generateQRData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              _simulateQRScan();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.goBack ||
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
                margin: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Avanze',
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -2,
                            ),
                          ),
                          TextSpan(
                            text: '360',
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: -2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Escanea el código QR desde tu\naplicación móvil para poder acceder al\ndashboard de avance360',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // QR Code Container
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _buildQRContent(),
              ),

              const SizedBox(height: 40),

              // Status and Session Info
              if (_isConnected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF10B981),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '¡Conexión Exitosa!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_sessionId != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ID de Sesión:',
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sessionId!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Instructions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    if (!_isConnected) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isScanning
                              ? 'Procesando conexión...'
                              : 'Presiona OK/Enter para simular escaneo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Usa el control remoto para navegar',
                        style: TextStyle(fontSize: 14, color: Colors.white60),
                      ),
                      const SizedBox(height: 12),
                      // Botón para regenerar QR
                      GestureDetector(
                        onTap: _regenerateQR,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'Regenerar QR',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Redirigiendo al dashboard...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRContent() {
    if (_isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 4),
            SizedBox(height: 16),
            Text(
              'Procesando...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      );
    }

    if (_isConnected) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 60),
            SizedBox(height: 16),
            Text(
              '¡Conectado!',
              style: TextStyle(
                fontSize: 16,
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
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // QR Code real usando qr_flutter
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: QrImageView(
              data: _qrData!,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'QR Login Code',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
