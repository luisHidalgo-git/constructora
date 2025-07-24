import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';

class TVProjectsGrid extends StatelessWidget {
  final List<ProjectModel> projects;
  final bool isLoading;
  final Function(ProjectModel) onProjectTap;

  const TVProjectsGrid({
    super.key,
    required this.projects,
    required this.isLoading,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Proyectos Activos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (projects.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${projects.length} proyectos',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(child: _buildProjectsContent()),
        ],
      ),
    );
  }

  Widget _buildProjectsContent() {
    if (isLoading) {
      return const LoadingWidget(color: Color(0xFF6366F1));
    }

    if (projects.isEmpty) {
      return EmptyStateWidget(
        title: 'No hay proyectos disponibles',
        message: 'Los proyectos aparecerán aquí cuando estén disponibles',
        icon: Icons.construction,
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    return GestureDetector(
      onTap: () => onProjectTap(project),
      child: ImageUtils.buildImageContainer(
        imageUrl: project.imageUrl,
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(12),
        placeholder: const Center(
          child: Icon(Icons.image_outlined, color: Colors.grey, size: 40),
        ),
      ),
    );
  }
}