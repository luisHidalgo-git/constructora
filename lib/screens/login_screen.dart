import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/social_login_button.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const SizedBox(height: 60),

              // Logo
              Center(
                child: Container(
                  child: Image.asset(
                    'lib/assets/image.png',
                    width: 280,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Subtitle
              Center(
                child: Text(
                  'Introduzca su dirección de correo electrónico y\ncontraseña para iniciar sesión',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle,
                ),
              ),

              const SizedBox(height: 60),

              // Email Field
              Text('Correo Electrónico', style: AppTextStyles.fieldLabel),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _emailController,
                hintText: 'hello@example.com',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 24),

              // Password Field
              Text('Contraseña', style: AppTextStyles.fieldLabel),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _passwordController,
                hintText: '••••••••••',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
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

              const SizedBox(height: 40),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Iniciar Sesión',
                    style: AppTextStyles.buttonText,
                  ),
                ),
              ),

              const SizedBox(height: 24),

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

              const SizedBox(height: 40),

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

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}