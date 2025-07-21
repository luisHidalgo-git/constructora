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
  Timer? _pollTimer;
  bool _isAuthenticated = false;
  String _statusMessage = 'Esperando escaneo del QR';

  @override
  void initState() {
    super.initState();
    _initializeTVSession();
    _startPollingForLogin();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    if (_sessionId != null) {
      TVAuthService.clearTVSession(_sessionId!);
    }
    super.dispose();
  }

  Future<void> _initializeTVSession() async {
    try {
      // Limpiar sesiones expiradas
      await TVAuthService.cleanupExpiredSessions();
      
      // Crear nueva sesión de TV
      _sessionId = await TVAuthService.createTVSession();
      
      // Crear datos del QR que incluyen información para el login
      final qrLoginData = {
        'type': 'tv_login',
        'sessionId': _sessionId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'appName': 'Avanze360',
        'action': 'authenticate_tv',
        'version': '1.0.0',
      };

      setState(() {
        _qrData = jsonEncode(qrLoginData);
      });

      print('🔍 TV Session initialized with QR data: $_qrData');
    } catch (e) {
      print('❌ Error initializing TV session: $e');
      setState(() {
        _statusMessage = 'Error al inicializar sesión';
      });
    }
  }

  void _startPollingForLogin() {
    // Polling real para verificar si el usuario escaneó el QR
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isAuthenticated && _sessionId != null) {
        _checkForLogin();
      }
    });
  }

  Future<void> _checkForLogin() async {
    if (_sessionId == null) return;
    
    try {
      final sessionStatus = await TVAuthService.checkTVSessionStatus(_sessionId!);
      
      if (sessionStatus == null) {
        setState(() {
          _statusMessage = 'Sesión no encontrada';
        });
        return;
      }
      
      final status = sessionStatus['status'] as String;
      
      switch (status) {
        case 'waiting':
          if (!_isScanning) {
            setState(() {
              _statusMessage = 'Esperando escaneo del QR';
            });
          }
          break;
          
        case 'authenticated':
          if (!_isAuthenticated && !_isScanning) {
            print('✅ TV Session authenticated, redirecting to dashboard...');
            await _handleSuccessfulAuthentication(sessionStatus);
          }
          break;
          
        case 'expired':
          setState(() {
            _statusMessage = 'Sesión expirada, generando nueva...';
          });
          await _initializeTVSession();
          break;
          
        default:
          setState(() {
            _statusMessage = 'Estado desconocido: $status';
          });
      }
    } catch (e) {
      print('❌ Error checking login status: $e');
      setState(() {
        _statusMessage = 'Error verificando estado';
      });
    }
  }
  
  Future<void> _handleSuccessfulAuthentication(Map<String, dynamic> sessionData) async {
    setState(() {
      _isScanning = true;
      _isAuthenticated = true;
      _statusMessage = 'Autenticación exitosa, redirigiendo...';
    });
    
    _pollTimer?.cancel();
    
    try {
      // Simular guardado de token de usuario en TV
      final userToken = sessionData['userToken'] as String?;
      if (userToken != null) {
        await AuthService.saveToken(userToken);
        
        // Simular datos de usuario para TV
        final userData = {
          '_id': 'tv_authenticated_user',
          'name': 'Usuario Autenticado',
          'email': 'tv@authenticated.com',
          'role': 'supervisor',
          'position': 'Supervisor TV',
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        
        await AuthService.saveUser(userData);
      }
      
      // Limpiar la sesión
      await TVAuthService.clearTVSession(_sessionId!);
      
      // Esperar un momento para mostrar el mensaje de éxito
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TVDashboardScreen()),
        );
      }
    } catch (e) {
      print('❌ Error handling successful authentication: $e');
      setState(() {
        _isScanning = false;
        _isAuthenticated = false;
        _statusMessage = 'Error en autenticación';
      });
    }
  }

  void _handleQRScanned() {
    if (_isScanning || _isAuthenticated || _sessionId == null) return;
    
    setState(() {
      _isScanning = true;
      _statusMessage = 'Simulando escaneo...';
    });

    // Simular proceso de autenticación manual (solo para testing)
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        // Simular autenticación de la sesión
        final success = await TVAuthService.authenticateTVSession(
          _sessionId!,
          'simulated_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (success) {
          print('✅ Manual authentication simulation successful');
          // El polling detectará el cambio de estado automáticamente
        } else {
          print('❌ Manual authentication simulation failed');
          setState(() {
            _isScanning = false;
            _statusMessage = 'Error en simulación';
          });
        }
      } catch (e) {
        print('❌ Error in manual authentication: $e');
        if (mounted) {
          setState(() {
            _isScanning = false;
            _statusMessage = 'Error en simulación';
          });
        }
      }
    });
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
              _handleQRScanned();
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
                      'Escanea el código QR desde tu\naplicación móvil para acceder al\ndashboard de Avanze360',
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
                width: 250,
                height: 250,
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
                child: _isScanning
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 4,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Autenticando...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        child: _qrData != null
                            ? QrImageView(
                                data: _qrData!,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                errorCorrectionLevel: QrErrorCorrectLevel.M,
                                padding: const EdgeInsets.all(8),
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
              ),

              const SizedBox(height: 40),

              // Session ID Display
              if (_sessionId != null && !_isScanning) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ID de Sesión:',
                        style: TextStyle(fontSize: 14, color: Colors.white60),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sessionId!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Instructions
              if (!_isScanning) ...[
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
                          'Presiona OK/Enter para simular escaneo (solo testing)',
                          style: TextStyle(
                            fontSize: 14,
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

              const SizedBox(height: 20),

              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isScanning 
                            ? Colors.orange 
                            : _isAuthenticated 
                                ? Colors.green 
                                : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
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
}