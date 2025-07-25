import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/tv_qr_screen.dart';
import 'utils/platform_utils.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno (opcional)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: .env file not found, using default values');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    // Limpiar sincronización al cerrar la app
    SyncService.stopSync();
    super.dispose();
  }

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
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    // Para testing: usar TVQRScreen si está en modo TV
    // En producción, esto se detectaría automáticamente
    if (kIsWeb) {
      // En web, mostrar TV por defecto para testing
      return const TVQRScreen();
    }

    // Para testing en móvil, puedes descomentar la siguiente línea:
    // return const TVQRScreen();

    // Si es móvil, mostrar splash screen primero
    return const SplashScreen();
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await AuthService.isAuthenticated();
      setState(() {
        _isAuthenticated = isAuth;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking auth status: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Si está autenticado, ir al home, sino al login
    return _isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
