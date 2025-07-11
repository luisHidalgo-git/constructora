import 'package:flutter/material.dart';
import '../widgets/project_card.dart';
import '../widgets/stats_card.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, Supervisor Carlos!',
                        style: AppTextStyles.header.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supervisor',
                        style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
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
                      Icons.notifications_outlined,
                      color: AppColors.iconGray,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
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
                  decoration: InputDecoration(
                    hintText: 'Buscar un proyecto...',
                    hintStyle: AppTextStyles.hintText.copyWith(fontSize: 14),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.iconGray,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: '12',
                      subtitle: 'Proyectos Activos',
                      color: AppColors.primary,
                      icon: Icons.construction,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      title: '5',
                      subtitle: 'Gastos Activos',
                      color: const Color(0xFFFF9500),
                      icon: Icons.receipt_long,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Projects Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Section Header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Proyectos Recientes',
                            style: AppTextStyles.header.copyWith(fontSize: 18),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Ver todos',
                              style: AppTextStyles.linkText.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Projects List
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: const [
                          ProjectCard(
                            title: 'Centro Comercial Plaza Norte',
                            subtitle: 'En construcción',
                            progress: 0.75,
                            status: 'Activo',
                            imageUrl: 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=400',
                          ),
                          SizedBox(height: 16),
                          ProjectCard(
                            title: 'Centro Comercial Plaza Norte',
                            subtitle: 'En construcción',
                            progress: 0.45,
                            status: 'Activo',
                            imageUrl: 'https://images.pexels.com/photos/1105766/pexels-photo-1105766.jpeg?auto=compress&cs=tinysrgb&w=400',
                          ),
                          SizedBox(height: 16),
                          ProjectCard(
                            title: 'Centro Comercial Plaza Norte',
                            subtitle: 'En construcción',
                            progress: 0.85,
                            status: 'Activo',
                            imageUrl: 'https://images.pexels.com/photos/1105766/pexels-photo-1105766.jpeg?auto=compress&cs=tinysrgb&w=400',
                          ),
                          SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
                _buildNavItem(Icons.home, 'Inicio', true),
                _buildNavItem(Icons.bar_chart, '', false),
                Container(
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
                _buildNavItem(Icons.folder_outlined, '', false),
                _buildNavItem(Icons.person_outline, '', false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.iconGray,
          size: 24,
        ),
        if (label.isNotEmpty) ...[
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
    );
  }
}