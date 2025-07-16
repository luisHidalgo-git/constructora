import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/social_login_button.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'platform_selection_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Por favor completa todos los campos', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result['success']) {
        _showMessage('¡Bienvenido ${result['user'].name}!');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        _showMessage(result['message'], isError: true);
      }
    } catch (e) {
      _showMessage('Error de conexión: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(
                      child: Container(
                        child: Image.asset(
                          'lib/assets/image.png',
                          width: 240,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Center(
                      child: Text(
                        'Introduzca su dirección de correo electrónico y\ncontraseña para iniciar sesión',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subtitle,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Email Field
                    Text('Correo Electrónico', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'hello@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 12),

                    // Password Field
                    Text('Contraseña', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: '••••••••••',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.iconGray,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Iniciar Sesión',
                                style: AppTextStyles.buttonText,
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Forgot Password
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Handle forgot password
                        },
                        child: Text(
                          'Olvidé mi contraseña',
                          style: AppTextStyles.linkText,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Register Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes cuenta? ',
                            style: AppTextStyles.subtitle,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Crear Cuenta',
                              style: AppTextStyles.linkText.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Social Login Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SocialLoginButton(
                          icon: Icons.apple,
                          onPressed: () {
                            // Handle Apple login
                          },
                        ),
                        const SizedBox(width: 24),
                        SocialLoginButton(
                          icon: Icons.g_mobiledata,
                          onPressed: () {
                            // Handle Google login
                          },
                        ),
                      ],
                    ),
                    
                    // Espacio adicional para evitar overflow
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
