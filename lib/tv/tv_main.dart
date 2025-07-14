import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tv_qr_login_screen.dart';
import '../utils/app_colors.dart';

class TVApp extends StatelessWidget {
  const TVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Constructora TV - Avanze 360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007AFF)),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        // Configuración específica para TV
        visualDensity: VisualDensity.comfortable,
      ),
      home: const TVQRLoginScreen(),
    );
  }
}