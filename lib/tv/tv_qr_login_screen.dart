import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'tv_dashboard_screen.dart';

class TVQRLoginScreen extends StatefulWidget {
  const TVQRLoginScreen({super.key});

  @override
  State<TVQRLoginScreen> createState() => _TVQRLoginScreenState();
}

class _TVQRLoginScreenState extends State<TVQRLoginScreen> {
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                    const SizedBox(height: 20),
                    const Text(
                      'Escanea el código QR desde tu\naplicación móvil para poder acceder al\ndashboard de avance360',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // QR Code Placeholder
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 4),
                ),
                child: _isScanning
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 6,
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code,
                            size: 200,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 60),

              // Instructions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Presiona OK/Enter para simular escaneo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Usa el control remoto para navegar',
                      style: TextStyle(
                        fontSize: 18,
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

  void _simulateQRScan() {
    setState(() {
      _isScanning = true;
    });

    // Simular proceso de escaneo
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TVDashboardScreen(),
        ),
      );
    });
  }
}