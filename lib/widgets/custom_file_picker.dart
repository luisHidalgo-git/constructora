import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class CustomFilePicker extends StatefulWidget {
  final Function(String)? onImageSelected;

  const CustomFilePicker({super.key, this.onImageSelected});

  @override
  State<CustomFilePicker> createState() => _CustomFilePickerState();
}

class _CustomFilePickerState extends State<CustomFilePicker> {
  String? _selectedImagePath;

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Seleccionar Imagen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Elige una opción para agregar la imagen del proyecto:',
                style: TextStyle(fontSize: 14, color: AppColors.textGray),
              ),
              const SizedBox(height: 20),

              // Camera Option
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _selectFromCamera();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tomar Foto',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Usar la cámara del dispositivo',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.iconGray,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Gallery Option
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _selectFromGallery();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Elegir de Galería',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Seleccionar desde la galería',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.iconGray,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _selectFromCamera() {
    // Simular selección de cámara
    setState(() {
      _selectedImagePath =
          "camera_image_${DateTime.now().millisecondsSinceEpoch}.jpg";
    });

    if (widget.onImageSelected != null) {
      widget.onImageSelected!(_selectedImagePath!);
    }

    // Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto tomada exitosamente'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _selectFromGallery() {
    // Simular selección de galería
    setState(() {
      _selectedImagePath =
          "gallery_image_${DateTime.now().millisecondsSinceEpoch}.jpg";
    });

    if (widget.onImageSelected != null) {
      widget.onImageSelected!(_selectedImagePath!);
    }

    // Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagen seleccionada de la galería'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedImagePath != null
                ? AppColors.primary.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
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
                color: (_selectedImagePath != null
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _selectedImagePath != null
                    ? Icons.check_circle
                    : Icons.camera_alt_outlined,
                color: _selectedImagePath != null
                    ? Colors.white
                    : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedImagePath != null
                  ? 'Imagen Seleccionada'
                  : 'Agregar Foto del Proyecto',
              style: (_selectedImagePath != null
                  ? AppTextStyles.fieldLabel.copyWith(
                      fontSize: 14,
                      color: AppColors.primary,
                    )
                  : AppTextStyles.hintText.copyWith(fontSize: 14)),
              textAlign: TextAlign.center,
            ),
            if (_selectedImagePath != null) ...[
              const SizedBox(height: 4),
              Text(
                'Toca para cambiar la imagen',
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'Toca para seleccionar una imagen',
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
