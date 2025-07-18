import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class CustomBudgetField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onChanged;

  const CustomBudgetField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  @override
  State<CustomBudgetField> createState() => _CustomBudgetFieldState();
}

class _CustomBudgetFieldState extends State<CustomBudgetField> {
  @override
  void initState() {
    super.initState();
    // Si el controller ya tiene texto y no empieza con $, agregarlo
    if (widget.controller.text.isNotEmpty && !widget.controller.text.startsWith('\$')) {
      widget.controller.text = '\$${widget.controller.text}';
    }
  }

  String _formatCurrency(String value) {
    // Remover todo excepto números
    String numbersOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numbersOnly.isEmpty) {
      return '';
    }

    // Convertir a número y formatear con comas
    int number = int.parse(numbersOnly);
    String formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return '\$$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: TextField(
        controller: widget.controller,
        style: AppTextStyles.inputText,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          // Formatear el valor automáticamente
          String formatted = _formatCurrency(value);
          
          // Solo actualizar si es diferente para evitar bucle infinito
          if (formatted != widget.controller.text) {
            widget.controller.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
          
          if (widget.onChanged != null) {
            widget.onChanged!();
          }
        },
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTextStyles.hintText,
          prefixIcon: Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              '\$',
              style: AppTextStyles.inputText.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}