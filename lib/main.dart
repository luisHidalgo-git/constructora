import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/platform_selection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Constructora - Avanze 360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007AFF)),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const PlatformSelectionScreen(),
    );
  }
}
