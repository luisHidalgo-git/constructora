import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart';
import '../widgets/project_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../models/project_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleProjects = ProjectModel.getSampleProjects();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QRScannerScreen(),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.iconGray,
                        size: 20,
                      ),
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

            const SizedBox(height: 16),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    SizedBox(
                      width: 180,
                      child: StatsCard(
                        title: '12',
                        subtitle: 'Proyectos Activos',
                        color: AppColors.primary,
                        icon: Icons.refresh,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 180,
                      child: StatsCard(
                        title: '3',
                        subtitle: 'Alertas Activas',
                        color: const Color(0xFFFF9500),
                        icon: Icons.notifications,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 180,
                      child: StatsCard(
                        title: '\$10.5M',
                        subtitle: 'Presupuesto Total',
                        color: const Color(0xFF10B981),
                        icon: Icons.attach_money,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 180,
                      child: StatsCard(
                        title: '74%',
                        subtitle: 'Progreso Medio',
                        color: const Color(0xFF8B5CF6),
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

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
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
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
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                        children: [
                          ...sampleProjects.map((project) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ProjectCard(
                              project: project,
                              title: project.name,
                              subtitle: project.description,
                              progress: project.progress,
                              status: project.status,
                              imageUrl: project.imageUrl,
                            ),
                          )).toList(),
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
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 0),
    );
  }
}