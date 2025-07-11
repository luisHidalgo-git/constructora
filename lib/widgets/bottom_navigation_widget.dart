import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../screens/home_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/update_project_screen.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;

  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProjectsScreen()),
          (route) => false,
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UpdateProjectScreen(),
          ),
        );
        break;
      case 3:
        // Navigate to Reports/Analytics screen (placeholder)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reportes - Próximamente'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 4:
        // Navigate to Profile screen (placeholder)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil - Próximamente'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                Icons.home,
                'Inicio',
                0,
                currentIndex == 0,
              ),
              _buildNavItem(
                context,
                Icons.bar_chart,
                'Proyectos',
                1,
                currentIndex == 1,
              ),
              GestureDetector(
                onTap: () => _onItemTapped(context, 2),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              _buildNavItem(
                context,
                Icons.folder_outlined,
                'Reportes',
                3,
                currentIndex == 3,
              ),
              _buildNavItem(
                context,
                Icons.person_outline,
                'Perfil',
                4,
                currentIndex == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primary : AppColors.iconGray,
            size: 24,
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppColors.primary : AppColors.iconGray,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}