import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/tv_service.dart';
import 'tv_dashboard_screen.dart';

class TVQRLoginScreen extends StatefulWidget {
  const TVQRLoginScreen({super.key});

  @override
  State<TVQRLoginScreen> createState() => _TVQRLoginScreenState();
}

class _TVQRLoginScreenState extends State<TVQRLoginScreen> {
  bool _isLoading = true;
  bool _isConnected = false;
  String? _sessionId;
  String? _qrCodeData;
  Map<String, dynamic>? _connectedUser;
  Timer? _statusTimer;
  Timer? _qrRefreshTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _qrRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQRCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await TVService.generateQR();
      
      if (result['success']) {
        setState(() {
          _sessionId = result['sessionId'];
          _qrCodeData = result['qrCode'];
          _isLoading = false;
        });
        
        // Iniciar polling para verificar conexión
        _startStatusPolling();
        
        // Programar regeneración del QR cada 9 minutos
        _qrRefreshTimer = Timer(const Duration(minutes: 9), () {
          if (mounted && !_isConnected) {
            _generateQRCode();
          }
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error generando código QR: $e';
        _isLoading = false;
      });
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_sessionId == null || _isConnected) return;
      
      try {
        final result = await TVService.getSessionStatus(_sessionId!);
        
        if (result['success'] && result['isConnected']) {
          setState(() {
            _isConnected = true;
            _connectedUser = result['user'];
          });
          
          timer.cancel();
                      Text(
                        _isConnected
                            ? '¡Conectado exitosamente!\nRedirigiendo al dashboard...'
                            : 'Escanea el código QR desde tu\naplicación móvil para poder acceder al\ndashboard de avance360',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: _isConnected ? Colors.green : Colors.white70,
                          height: 1.4,
                        ),
                    sessionId: _sessionId!,
                    connectedUser: _connectedUser!,
                  ),
                ),
              );
            }
          });
        }
      } catch (e) {
        print('Error checking session status: $e');
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
              if (!_isLoading && !_isConnected) {
                _generateQRCode();
              }
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
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
              ],
            ),
                  child: _isLoading
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                margin: const EdgeInsets.only(bottom: 40),
                      : _error != null
                          ? Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 40,
                                      color: Colors.red,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Error',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _isConnected
                              ? Container(
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 60,
                                          color: Colors.green,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          '¡Conectado!',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : _qrCodeData != null
                                  ? Container(
                                      margin: const EdgeInsets.all(8),
                                      child: Image.memory(
                                        base64Decode(_qrCodeData!.split(',')[1]),
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : Container(
                                      margin: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.qr_code,
                                          size: 120,
                                          color: Colors.grey,
                                        ),
                                      ),
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

              // QR Code
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                // Connected User Info
                if (_isConnected && _connectedUser != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Usuario Conectado',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _connectedUser!['name'] ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _connectedUser!['position'] ?? 'Supervisor',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                ),
                child: _isScanning
                    ? const Center(
                        child: CircularProgressIndicator(
                      if (!_isConnected) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _error != null ? Colors.red : AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error != null
                                ? 'Presiona OK/Enter para reintentar'
                                : _isLoading
                                    ? 'Generando código QR...'
                                    : 'Esperando conexión desde móvil',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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
                        const SizedBox(height: 16),
                        Text(
                          _error != null
                              ? 'Error: $_error'
                              : 'Usa el control remoto para navegar',
                          style: TextStyle(
                            fontSize: 14,
                            color: _error != null ? Colors.red : Colors.white60,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Usa el control remoto para navegar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
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