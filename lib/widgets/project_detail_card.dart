import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../screens/update_project_screen.dart';
import '../models/project_model.dart';

class ProjectDetailCard extends StatelessWidget {
  final ProjectModel project;
  final String title;
  final String location;
  final String date;
  final double progress;
  final String status;
  final String budget;
  final String imageUrl;

  const ProjectDetailCard({
    super.key,
    required this.project,
    required this.title,
    required this.location,
    required this.date,
    required this.progress,
    required this.status,
    required this.budget,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpdateProjectScreen(project: project),
          ),
        );
      },
      child: Container(
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
            // Header with title and status
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textGray,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                location,
                                style: AppTextStyles.subtitle.copyWith(
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Project Image
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Progress and Budget Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Budget Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gasto emocional ABC',
                    style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Presupuesto: $budget',
                    style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor() {
    if (progress >= 0.7) {
      return const Color(0xFF10B981); // Green
    } else if (progress >= 0.4) {
      return const Color(0xFF3B82F6); // Blue
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }
}
