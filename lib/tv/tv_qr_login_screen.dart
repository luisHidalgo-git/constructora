import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    _generateQRData();
    _startPollingForLogin();
  }

  void _generateQRData() {
    // Generar un ID de sesión único
    _sessionId = _generateSessionId();

    // Crear datos del QR que incluyen información para el login
    final qrLoginData = {
      'type': 'tv_login',
      'sessionId': _sessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'appName': 'Avanze360',
    };

    setState(() {
      _qrData = jsonEncode(qrLoginData);
    });

    print('🔍 Generated QR data: $_qrData');
  }

  String _generateSessionId() {
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

  void _startPollingForLogin() {
    // Simular polling para verificar si el usuario escaneó el QR
    // En una implementación real, esto sería una conexión WebSocket o polling a un servidor
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isScanning) {
        _checkForLogin();
      }
    });
  }

  void _checkForLogin() {
    // Simular verificación de login
    // En una implementación real, verificarías con el servidor si el QR fue escaneado
    _startPollingForLogin();
  }

  void _simulateQRScan() {
    setState(() {
      _isScanning = true;
    });

    // Simular proceso de autenticación
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        // Simular login exitoso con datos de usuario demo
        await AuthService.logout(); // Limpiar cualquier sesión anterior

        // Simular que se guardaron datos de usuario después del escaneo
        final userData = {
          '_id': 'demo_tv_user',
          'name': 'Usuario TV Demo',
          'email': 'tv@demo.com',
          'role': 'supervisor',
          'position': 'Supervisor TV',
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        // Guardar datos simulados
        await AuthService.saveUser(userData);
        await AuthService.saveToken(
          'demo_tv_token_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TVDashboardScreen()),
          );
        }
      } catch (e) {
        print('❌ Error in simulated login: $e');
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
          _showError('Error en el login simulado');
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isScanning
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 4,
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _qrData != null
                            ? _buildQRCode(_qrData!)
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
              ),

              const SizedBox(height: 40),

              // Session ID Display
              if (_sessionId != null) ...[
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
                const SizedBox(height: 20),
              ],

              // Instructions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Presiona OK/Enter para simular escaneo',
                        style: TextStyle(
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCode(String data) {
    // Crear una representación visual simple del QR
    // En una implementación real, usarías un paquete como qr_flutter
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simulación visual de QR code
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 64,
              itemBuilder: (context, index) {
                // Generar patrón pseudo-aleatorio basado en los datos
                final hash = data.hashCode + index;
                final isBlack = hash % 3 == 0;
                return Container(
                  decoration: BoxDecoration(
                    color: isBlack ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'QR Login Code',
            style: TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
