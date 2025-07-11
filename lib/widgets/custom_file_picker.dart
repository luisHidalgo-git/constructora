import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class CustomFilePicker extends StatefulWidget {
  const CustomFilePicker({super.key});

  @override
  State<CustomFilePicker> createState() => _CustomFilePickerState();
}

class _CustomFilePickerState extends State<CustomFilePicker> {
  String? _selectedFileName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Simulate file picker
        setState(() {
          _selectedFileName = "proyecto_imagen.jpg";
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFileName ?? 'Subir Foto',
              style: _selectedFileName != null
                  ? AppTextStyles.fieldLabel.copyWith(
                      fontSize: 14,
                      color: AppColors.primary,
                    )
                  : AppTextStyles.hintText.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
