import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/tv_auth_service.dart';
import '../utils/platform_utils.dart';
import 'tv_user_dashboard_screen.dart';
import 'tv_dashboard_screen.dart';

class TVQRScreen extends StatefulWidget {
  const TVQRScreen({super.key});

  @override
  State<TVQRScreen> createState() => _TVQRScreenState();
}

class _TVQRScreenState extends State<TVQRScreen> with TickerProviderStateMixin {
  String? _currentQRCode;
  DateTime? _expiresAt;
  Timer? _regenerateTimer;
  Timer? _checkStatusTimer;
  bool _isLoading = true;
  String _status = 'Generando código QR...';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateNewQR();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  // Método para guardar el token en el almacenamiento local de la TV
  Future<void> _saveTokenForTV(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('✅ Token saved for TV: ${token.substring(0, 20)}...');
    } catch (e) {
      print('❌ Error saving token for TV: $e');
    }
  }

  Future<void> _generateNewQR() async {
    setState(() {
      _isLoading = true;
      _status = 'Generando nuevo código QR...';
    });

    try {
      final result = await TVAuthService.generateQRCode();
      
      if (result['success']) {
        setState(() {
          _currentQRCode = result['qrCode'];
          _expiresAt = result['expiresAt'];
          _isLoading = false;
          _status = 'Escanea el código QR desde tu aplicación móvil';
        });

        _startTimers();
      } else {
        setState(() {
          _isLoading = false;
          _status = 'Error: ${result['message']}';
        });
        
        // Reintentar en 5 segundos
        Timer(const Duration(seconds: 5), _generateNewQR);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error de conexión. Reintentando...';
      });
      
      // Reintentar en 5 segundos
      Timer(const Duration(seconds: 5), _generateNewQR);
    }
  }

  void _startTimers() {
    _stopTimers();

    if (_currentQRCode != null && _expiresAt != null) {
      // Timer para regenerar QR automáticamente
      final timeUntilExpiry = _expiresAt!.difference(DateTime.now());
      _regenerateTimer = Timer(timeUntilExpiry, () {
        print('🔄 QR code expired, generating new one...');
        _generateNewQR();
      });

      // Timer para verificar estado cada 2 segundos
      _checkStatusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _checkQRStatus();
      });
    }
  }

  Future<void> _checkQRStatus() async {
    if (_currentQRCode == null) return;

    try {
      final result = await TVAuthService.checkQRStatus(_currentQRCode!);
      
      if (result['success']) {
        final status = result['status'];
        
        switch (status) {
          case 'authenticated':
            print('✅ User authenticated successfully!');
            _stopTimers();
            
            // Guardar el token en el almacenamiento local de la TV
            if (result['token'] != null) {
              await _saveTokenForTV(result['token']);
            }
            
            // Navegar a dashboard con datos del usuario
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => TVDashboardScreen(
                  user: result['user'],
                ),
              ),
              (route) => false,
            );
            break;
            
          case 'expired':
            print('⏰ QR code expired, generating new one...');
            _generateNewQR();
            break;
            
          case 'waiting':
            // Continuar esperando
            break;
            
          default:
            print('❓ Unknown status: $status');
        }
      }
    } catch (e) {
      print('❌ Error checking QR status: $e');
    }
  }

  void _stopTimers() {
    _regenerateTimer?.cancel();
    _checkStatusTimer?.cancel();
  }

  String _getTimeRemaining() {
    if (_expiresAt == null) return '';
    
    final remaining = _expiresAt!.difference(DateTime.now());
    if (remaining.isNegative) return 'Expirado';
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  // Método para testing - permite cambiar a modo TV fácilmente
  static bool get isTVMode => true; // Cambiar a false para modo móvil normal

  @override
  void dispose() {
    _stopTimers();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF2D2D2D),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                margin: const EdgeInsets.only(bottom: 40),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Avanze',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -2,
                        ),
                      ),
                      TextSpan(
                        text: '360',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: -2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Subtitle
              Container(
                margin: const EdgeInsets.only(bottom: 60),
                child: Text(
                  'Escanea el código QR desde tu\naplicación móvil para iniciar sesión en el\ndashboard de Avanze360',
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // QR Code Container
              if (_isLoading)
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  ),
                )
              else if (_currentQRCode != null)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _currentQRCode!,
                          version: QrVersions.auto,
                          size: 260,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Status Text
              Text(
                _status,
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}