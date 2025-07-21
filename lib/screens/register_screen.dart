import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/social_login_button.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart'; // Ajusta la ruta según tu estructura

// Asegúrate de que RegisterScreen sea un StatefulWidget
class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
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
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Por favor ingresa tu nombre completo', isError: true);
      return false;
    }

    if (_emailController.text.trim().isEmpty) {
      _showMessage('Por favor ingresa tu email', isError: true);
      return false;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showMessage('Por favor ingresa un email válido', isError: true);
      return false;
    }

    if (_passwordController.text.length < 6) {
      _showMessage(
        'La contraseña debe tener al menos 6 caracteres',
        isError: true,
      );
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Las contraseñas no coinciden', isError: true);
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
                        child: Image.asset(
                          'lib/assets/image.png',
                          width: 200,
                          height: 70,
                          fit: BoxFit.contain,
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
                    Text('Nombre Completo', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _nameController,
                      hintText: 'Ej. Carlos Mendoza',
                    ),

                    const SizedBox(height: 16),

                    // Email Field
                    Text('Correo Electrónico', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'carlos@constructora.com',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // Position Field
                    Text('Cargo/Posición', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _positionController,
                      hintText:
                          'Ej. Supervisor de Obra, Supervisor Eléctrico, etc.',
                    ),

                    const SizedBox(height: 16),

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

                    const SizedBox(height: 16),

                    // Confirm Password Field
                    Text(
                      'Confirmar Contraseña',
                      style: AppTextStyles.fieldLabel,
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: '••••••••••',
                      obscureText: _obscureConfirmPassword,
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
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
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
                                'Crear Cuenta',
                                style: AppTextStyles.buttonText,
                              ),
                      ),
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
                                  builder: (context) => RegisterScreen(),
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
