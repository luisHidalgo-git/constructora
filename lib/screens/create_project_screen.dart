import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_date_field.dart';
import '../widgets/custom_file_picker.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _projectManagerController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void dispose() {
    _projectNameController.dispose();
    _clientNameController.dispose();
    _projectManagerController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Crear Proyecto',
                      style: AppTextStyles.header.copyWith(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Name
                    Text(
                      'Nombre del proyecto',
                      style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _projectNameController,
                      hintText: 'Complejo Industrial Norte',
                    ),

                    const SizedBox(height: 24),

                    // Client Name
                    Text(
                      'Nombre del cliente',
                      style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _clientNameController,
                      hintText: 'Ej. Manufactura Industrial SAC',
                    ),

                    const SizedBox(height: 24),

                    // Project Manager
                    Text(
                      'Nombre del proyecto',
                      style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _projectManagerController,
                      hintText: 'Ej. Una breve descripción del proyecto...',
                    ),

                    const SizedBox(height: 24),

                    // Location
                    Text(
                      'Ubicación',
                      style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _locationController,
                      hintText: 'Ej. Santiago Papasquiero',
                    ),

                    const SizedBox(height: 24),

                    // Total Budget
                    Text(
                      'Presupuesto Total',
                      style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _budgetController,
                      hintText: '\$2,500,000',
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 24),

                    // Date Fields
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha de Inicio',
                                style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              CustomDateField(
                                controller: _startDateController,
                                hintText: 'dd/mm/aaaa',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha de Fin',
                                style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              CustomDateField(
                                controller: _endDateController,
                                hintText: 'dd/mm/aaaa',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // File Picker
                    const CustomFilePicker(),

                    const SizedBox(height: 40),

                    // Create Project Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle project creation
                          Navigator.pop(context);
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
                          'Crear Proyecto',
                          style: AppTextStyles.buttonText,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}