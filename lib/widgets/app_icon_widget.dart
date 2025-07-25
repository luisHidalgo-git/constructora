import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppIconWidget extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool showShadow;

  const AppIconWidget({
    super.key,
    this.size = 60,
    this.backgroundColor,
    this.iconColor,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: (backgroundColor ?? AppColors.primary).withOpacity(0.3),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Icono principal de construcción
          Center(
            child: Icon(
              Icons.construction,
              size: size * 0.5,
              color: iconColor ?? Colors.white,
            ),
          ),
          
          // Pequeño detalle de herramientas en la esquina
          Positioned(
            top: size * 0.15,
            right: size * 0.15,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.white).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.build,
                size: size * 0.12,
                color: iconColor ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}