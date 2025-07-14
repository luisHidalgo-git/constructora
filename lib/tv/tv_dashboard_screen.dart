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
    // Agregar más proyectos para llenar la pantalla
    _projects.addAll([
      ProjectModel(
        id: '4',
        name: 'Centro Comercial Plaza Norte',
        clientName: 'Grupo Inmobiliario ABC',
        description: 'En construcción',
        location: 'Manta',
        budget: 'USD 1,200,000',
        startDate: '05/03/2024',
        endDate: '05/12/2024',
        progress: 0.80,
        status: 'Activo',
        keyIndicators: {
          'Calidad': 0.88,
          'Tiempo': 0.75,
          'Presupuesto': 0.92,
          'Satisfacción': 0.85,
        },
        imageUrl:
            'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=400',
      ),
      ProjectModel(
        id: '5',
        name: 'Centro Comercial Plaza Norte',
        clientName: 'Constructora del Sur',
        description: 'En construcción',
        location: 'Loja',
        budget: 'USD 950,000',
        startDate: '20/04/2024',
        endDate: '20/11/2024',
        progress: 0.45,
        status: 'Activo',
        keyIndicators: {
          'Calidad': 0.65,
          'Tiempo': 0.58,
          'Presupuesto': 0.72,
          'Satisfacción': 0.68,
        },
        imageUrl:
            'https://images.pexels.com/photos/1105766/pexels-photo-1105766.jpeg?auto=compress&cs=tinysrgb&w=400',
      ),
      ProjectModel(
        id: '6',
        name: 'Centro Comercial Plaza Norte',
        clientName: 'Inmobiliaria Central',
        description: 'En construcción',
        location: 'Ambato',
        budget: 'USD 1,750,000',
        startDate: '12/02/2024',
        endDate: '12/09/2024',
        progress: 0.45,
        status: 'Activo',
        keyIndicators: {
          'Calidad': 0.70,
          'Tiempo': 0.48,
          'Presupuesto': 0.65,
          'Satisfacción': 0.62,
        },
        imageUrl:
            'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=400',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.goBack ||
                event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  height: 60,
                  child: Row(
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Avanze',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                letterSpacing: -1,
                              ),
                            ),
                            TextSpan(
                              text: '360',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Monitor de Proyectos',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Hola, Supervisor Carlos!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  'Bienvenido',
                                  style: TextStyle(
                                    fontSize: 12,
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

                const SizedBox(height: 16),

                // Stats Cards
                Container(
                  height: 100,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatsCard(
                          '12',
                          'Proyectos Activos',
                          AppColors.primary,
                          Icons.refresh,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatsCard(
                          '3',
                          'Alertas Activas',
                          const Color(0xFFFF9500),
                          Icons.add_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatsCard(
                          '\$10.5M',
                          'Presupuesto Total',
                          const Color(0xFF10B981),
                          Icons.attach_money,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                ),

                const SizedBox(height: 16),

                // Main Content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side - Projects List (2 columns)
                      Expanded(flex: 2, child: _buildProjectsList()),

                      const SizedBox(width: 16),

                      // Right side - Project Detail and Activity
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selected Project Detail
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Project Title
                                    Text(
                                      _projects[_selectedProjectIndex].name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _projects[_selectedProjectIndex]
                                          .clientName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textGray,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),

                                    // KPIs Section
                                    const Text(
                                      'KPIs',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // KPIs List with Scroll
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: _projects[_selectedProjectIndex].keyIndicators.entries.map((
                                            entry,
                                          ) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          entry.key,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                color: AppColors
                                                                    .textGray,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${(entry.value * 100).toInt()}%',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              _getIndicatorColor(
                                                                entry.value,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Container(
                                                    height: 4,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            2,
                                                          ),
                                                    ),
                                                    child: FractionallySizedBox(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      widthFactor: entry.value,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color:
                                                              _getIndicatorColor(
                                                                entry.value,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                2,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Activity Section
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Actividad Reciente',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Activity List with Scroll
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            _buildActivityItem(
                                              'INSTALACIÓN DE SISTEMAS ELÉCTRICOS COMPLETADA',
                                              '15/11/2024',
                                            ),
                                            const SizedBox(height: 8),
                                            _buildActivityItem(
                                              'REVISIÓN DE SISTEMAS ELÉCTRICOS COMPLETADA',
                                              '14/11/2024',
                                            ),
                                            const SizedBox(height: 8),
                                            _buildActivityItem(
                                              'INSTALACIÓN DE SISTEMAS ELÉCTRICOS COMPLETADA',
                                              '13/11/2024',
                                            ),
                                            const SizedBox(height: 8),
                                            _buildActivityItem(
                                              'REVISIÓN DE SISTEMAS ELÉCTRICOS COMPLETADA',
                                              '12/11/2024',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList() {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() {
              _selectedProjectIndex = (_selectedProjectIndex - 1).clamp(
                0,
                _projects.length - 1,
              );
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() {
              _selectedProjectIndex = (_selectedProjectIndex + 1).clamp(
                0,
                _projects.length - 1,
              );
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
      child: SingleChildScrollView(
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: _projects.asMap().entries.map((entry) {
            final index = entry.key;
            final project = entry.value;
            final isSelected = index == _selectedProjectIndex;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    // Project Image
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        image: DecorationImage(
                          image: NetworkImage(project.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Project Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Project name
                          Flexible(
                            child: Text(
                              project.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(height: 2),

                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              project.status,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 2),

                          // Days remaining
                          Text(
                            '${_calculateDaysRemaining(project)} días restantes',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // Progress Bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: project.progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getProgressColor(
                                        project.progress,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${(project.progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 9,
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
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String date) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: const TextStyle(fontSize: 9, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }

  int _calculateDaysRemaining(ProjectModel project) {
    // Simulación de cálculo de días restantes
    final random = [15, 30, 45, 60, 75, 90];
    return random[project.id.hashCode % random.length];
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

  Color _getIndicatorColor(double value) {
    if (value >= 0.8) {
      return const Color(0xFF10B981); // Green
    } else if (value >= 0.6) {
      return const Color(0xFF3B82F6); // Blue
    } else if (value >= 0.4) {
      return const Color(0xFFFF9500); // Orange
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
