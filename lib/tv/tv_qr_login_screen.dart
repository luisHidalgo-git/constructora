import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
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
    // Generar un ID de sesión único
    _sessionId = await TVAuthService.createTVSession();

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

  void _startPollingForAuth() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && !_isScanning && _sessionId != null) {
        _checkForAuth();
      }
    });
  }

  Future<void> _checkForAuth() async {
    if (_sessionId == null) return;
    
    try {
      final sessionStatus = await TVAuthService.checkTVSessionStatus(_sessionId!);
      
      if (sessionStatus == null) {
        print('❌ Session not found, regenerating...');
        await _generateQRData();
        return;
      }
      
      if (sessionStatus['status'] == 'authenticated') {
        print('✅ Session authenticated, proceeding to dashboard...');
        _pollingTimer?.cancel();
        
        setState(() {
          _isScanning = true;
        });
        
        // Simular proceso de login
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
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
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
    });

    Future.delayed(const Duration(seconds: 1), () async {
      try {
        if (_sessionId != null) {
          // Simular autenticación exitosa
          final success = await TVAuthService.authenticateTVSession(
            _sessionId!,
            'demo_token_${DateTime.now().millisecondsSinceEpoch}',
          );
          
          if (success && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TVDashboardScreen()),
            );
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

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
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
