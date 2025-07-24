import 'package:flutter/material.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_date_field.dart';
import '../../../widgets/custom_budget_field.dart';
import '../../../widgets/location_picker_widget.dart';
import '../../../utils/app_text_styles.dart';

class ProjectFormFields extends StatelessWidget {
  final TextEditingController projectNameController;
  final TextEditingController clientNameController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final TextEditingController budgetController;
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final VoidCallback? onFieldChanged;

  const ProjectFormFields({
    super.key,
    required this.projectNameController,
    required this.clientNameController,
    required this.descriptionController,
    required this.locationController,
    required this.budgetController,
    required this.startDateController,
    required this.endDateController,
    this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project Name
        Text(
          'Nombre del proyecto',
          style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: projectNameController,
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
          controller: clientNameController,
          hintText: 'Ej. Manufactura Industrial SAC',
        ),

        const SizedBox(height: 24),

        // Project Description
        Text(
          'Descripción del proyecto',
          style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: descriptionController,
          hintText: 'Ej. Una breve descripción del proyecto...',
        ),

        const SizedBox(height: 24),

        // Location
        Text(
          'Ubicación',
          style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 8),
        LocationPickerWidget(
          initialLocation: locationController.text,
          onLocationSelected: (location) {
            locationController.text = location;
            if (onFieldChanged != null) {
              onFieldChanged!();
            }
          },
        ),

        const SizedBox(height: 24),

        // Total Budget
        Text(
          'Presupuesto Total',
          style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 8),
        CustomBudgetField(
          controller: budgetController,
          hintText: '2,500,000',
          onChanged: onFieldChanged,
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
                    controller: startDateController,
                    hintText: 'dd/mm/aaaa',
                    onChanged: onFieldChanged,
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
                    controller: endDateController,
                    hintText: 'dd/mm/aaaa',
                    onChanged: onFieldChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}