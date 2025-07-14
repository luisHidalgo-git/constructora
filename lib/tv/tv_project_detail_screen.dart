import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../models/project_model.dart';

class TVProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;

  const TVProjectDetailScreen({super.key, required this.project});

  @override
  State<TVProjectDetailScreen> createState() => _TVProjectDetailScreenState();
}

class _TVProjectDetailScreenState extends State<TVProjectDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
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
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        widget.project.name,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.project.status,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Main Content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column - Project Image and Basic Info
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Project Image
                            Container(
                              height: 400,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  image: NetworkImage(widget.project.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Basic Info Cards
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    'Cliente',
                                    widget.project.clientName,
                                    Icons.business,
                                    AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildInfoCard(
                                    'Ubicación',
                                    widget.project.location,
                                    Icons.location_on,
                                    const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    'Presupuesto',
                                    widget.project.budget,
                                    Icons.attach_money,
                                    const Color(0xFFFF9500),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildInfoCard(
                                    'Progreso',
                                    '${(widget.project.progress * 100).toInt()}%',
                                    Icons.trending_up,
                                    const Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 40),

                      // Right Column - KPIs and Activity
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // KPIs Section
                            Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'KPIs',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  ...widget.project.keyIndicators.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 25),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                entry.key,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              Text(
                                                '${(entry.value * 100).toInt()}%',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getIndicatorColor(entry.value),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: entry.value,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: _getIndicatorColor(entry.value),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Activity Section
                            Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Actividad Reciente',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  _buildActivityItem(
                                    'INSTALACIÓN DE SISTEMAS ELÉCTRICOS COMPLETADA',
                                    '15/11/2024',
                                    Icons.electrical_services,
                                    const Color(0xFF10B981),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildActivityItem(
                                    'REVISIÓN DE SISTEMAS ELÉCTRICOS COMPLETADA',
                                    '14/11/2024',
                                    Icons.check_circle,
                                    AppColors.primary,
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

                // Navigation hint
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_backspace,
                        color: AppColors.textGray,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Presiona Back/Escape para regresar',
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
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String date, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
}