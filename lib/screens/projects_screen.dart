import 'package:flutter/material.dart';
import '../widgets/project_detail_card.dart';
import '../screens/create_project_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

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
                      'Mis Proyectos',
                      style: AppTextStyles.header.copyWith(fontSize: 20),
                    ),
                  ),
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
                      Icons.search,
                      color: AppColors.iconGray,
                      size: 20,
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
                  ProjectDetailCard(
                    title: 'Centro Comercial Plaza Norte',
                    location: 'Guayaquil',
                    date: '23 Nov 2024',
                    progress: 0.65,
                    status: 'Activo',
                    budget: 'USD 2,500,000',
                    imageUrl: 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800',
                  ),
                  SizedBox(height: 20),
                  ProjectDetailCard(
                    title: 'Centro Comercial Plaza Norte',
                    location: 'Guayaquil',
                    date: '23 Nov 2024',
                    progress: 0.45,
                    status: 'Activo',
                    budget: 'USD 2,500,000',
                    imageUrl: 'https://images.pexels.com/photos/1105766/pexels-photo-1105766.jpeg?auto=compress&cs=tinysrgb&w=800',
                  ),
                  SizedBox(height: 100),
                ],
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
                _buildNavItem(Icons.home_outlined, false),
                _buildNavItem(Icons.bar_chart, true),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateProjectScreen(),
                      ),
                    );
                  },
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
                _buildNavItem(Icons.folder_outlined, false),
                _buildNavItem(Icons.person_outline, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Icon(
      icon,
      color: isActive ? AppColors.primary : AppColors.iconGray,
      size: 24,
    );
  }
}