import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../models/project_model.dart';
import 'tv_project_detail_screen.dart';

class TVDashboardScreen extends StatefulWidget {
  const TVDashboardScreen({super.key});

  @override
  State<TVDashboardScreen> createState() => _TVDashboardScreenState();
}

class _TVDashboardScreenState extends State<TVDashboardScreen> {
  int _selectedProjectIndex = 0;
  late List<ProjectModel> _projects;

  @override
  void initState() {
    super.initState();
    _projects = ProjectModel.getSampleProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Avanze',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            letterSpacing: -1,
                          ),
                        ),
                        TextSpan(
                          text: '360',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  const Text(
                    'Monitor de Proyectos',
                    style: TextStyle(
                      fontSize: 24,
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
                    child: const Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, Supervisor Carlos!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Bienvenido',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      '12',
                      'Proyectos Activos',
                      AppColors.primary,
                      Icons.refresh,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatsCard(
                      '3',
                      'Alertas Activas',
                      const Color(0xFFFF9500),
                      Icons.notifications,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatsCard(
                      '\$10.5M',
                      'Presupuesto Total',
                      const Color(0xFF10B981),
                      Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatsCard(
                      '74%',
                      'Progreso Medio',
                      const Color(0xFF8B5CF6),
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Projects Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Proyectos Recientes',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Ver todo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: _buildProjectsList(),
                    ),
                  ],
                ),
              ),

              // Navigation hint
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: AppColors.textGray,
                      size: 20,
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textGray,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Navega con las flechas del control remoto',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textGray,
                      ),
                    ),
                    SizedBox(width: 20),
                    Text(
                      'OK/Enter para seleccionar',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList() {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() {
              _selectedProjectIndex = (_selectedProjectIndex - 1).clamp(0, _projects.length - 1);
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() {
              _selectedProjectIndex = (_selectedProjectIndex + 1).clamp(0, _projects.length - 1);
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
                     event.logicalKey == LogicalKeyboardKey.enter) {
            _openProjectDetail(_projects[_selectedProjectIndex]);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: ListView.builder(
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          final isSelected = index == _selectedProjectIndex;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isSelected 
                  ? Border.all(color: AppColors.primary, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isSelected ? 20 : 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Project Image
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(project.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 30),
                  
                  // Project Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                project.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                project.status,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.textGray,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              project.location,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(width: 30),
                            Text(
                              project.budget,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Progress Bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: project.progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _getProgressColor(project.progress),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(project.progress * 100).toInt()}% completado',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.7) {
      return const Color(0xFF10B981); // Green
    } else if (progress >= 0.4) {
      return const Color(0xFF3B82F6); // Blue
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }

  void _openProjectDetail(ProjectModel project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TVProjectDetailScreen(project: project),
      ),
    );
  }
}