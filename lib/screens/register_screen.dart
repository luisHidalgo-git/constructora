import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
import '../features/auth/widgets/auth_form_field.dart';
import '../features/auth/widgets/auth_button.dart';
import '../core/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  // Variables de estado
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: 'supervisor',
        position: _positionController.text.trim().isEmpty
            ? 'Supervisor de Obra'
            : _positionController.text.trim(),
      );

      if (result['success']) {
        _showMessage('¡Registro exitoso! Bienvenido ${result['user'].name}!');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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

  bool _validateForm() {
    final nameError = Validators.validateName(_nameController.text);
    final emailError = Validators.validateEmail(_emailController.text);
    final passwordError = Validators.validatePassword(_passwordController.text);
    final confirmError = Validators.validatePasswordConfirmation(
      _passwordController.text,
      _confirmPasswordController.text,
    );
    
    if (nameError != null) {
      _showMessage(nameError, isError: true);
      return false;
    }
    
    if (emailError != null) {
      _showMessage(emailError, isError: true);
      return false;
    }
    
    if (passwordError != null) {
      _showMessage(passwordError, isError: true);
      return false;
    }
    
    if (confirmError != null) {
      _showMessage(confirmError, isError: true);
      return false;
    }

    return true;
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
              minHeight:
                  MediaQuery.of(context).size.height -
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
                    // Back Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.iconDark,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Logo
                    Center(
                      child: Container(
                        child: Column(
                          children: [
                            // Icono de la app
                            Container(
                              width: 70,
                              height: 70,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.construction,
                                size: 35,
                                color: Colors.white,
                              ),
                            ),
                            
                            // Texto del logo
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Avanze',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                      letterSpacing: -1.2,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '360',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      letterSpacing: -1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Center(
                      child: Text(
                        'Crear Cuenta',
                        style: AppTextStyles.header.copyWith(fontSize: 24),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: Text(
                        'Completa los datos para crear tu cuenta\nen Avanze 360',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subtitle,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Name Field
                    AuthFormField(
                      label: 'Nombre Completo',
                      controller: _nameController,
                      hintText: 'Ej. Carlos Mendoza',
                      validator: Validators.validateName,
                    ),

                    const SizedBox(height: 16),

                    // Email Field
                    AuthFormField(
                      label: 'Correo Electrónico',
                      controller: _emailController,
                      hintText: 'carlos@constructora.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ),

                    const SizedBox(height: 16),

                    // Position Field
                    AuthFormField(
                      label: 'Cargo/Posición',
                      controller: _positionController,
                      hintText:
                          'Ej. Supervisor de Obra, Supervisor Eléctrico, etc.',
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    AuthFormField(
                      label: 'Contraseña',
                      controller: _passwordController,
                      hintText: '••••••••••',
                      obscureText: _obscurePassword,
                      validator: Validators.validatePassword,
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

                    const SizedBox(height: 16),

                    // Confirm Password Field
                    AuthFormField(
                      label: 'Confirmar Contraseña',
                      controller: _confirmPasswordController,
                      hintText: '••••••••••',
                      obscureText: _obscureConfirmPassword,
                      validator: (value) => Validators.validatePasswordConfirmation(
                        _passwordController.text,
                        value,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.iconGray,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Register Button
                    AuthButton(
                      text: 'Crear Cuenta',
                      onPressed: _handleRegister,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 16),

                    // Login Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes cuenta? ',
                            style: AppTextStyles.subtitle,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Iniciar Sesión',
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

                    // Espacio adicional para evitar overflow
                    SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom > 0
                          ? 20
                          : 0,
                    ),
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
