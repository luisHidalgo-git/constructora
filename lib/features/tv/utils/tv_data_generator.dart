import '../../../models/project_model.dart';
import '../../../core/utils/formatters.dart';

class TVDataGenerator {
  static List<Map<String, dynamic>> generateRecentUpdatesFromProjects(
    List<ProjectModel> projects,
  ) {
    final List<Map<String, dynamic>> recentUpdates = [];

    // Generar actualizaciones reales basadas en los datos de los proyectos
    for (int i = 0; i < projects.length && i < 4; i++) {
      final project = projects[i];
      final daysAgo = i + 1;
      final updateDate = DateTime.now().subtract(Duration(days: daysAgo));

      String updateType;
      String updateDescription;

      // Determinar tipo de actualización basado en datos reales del proyecto
      if (project.progress >= 0.9) {
        updateType = 'Actualización';
        updateDescription = 'Proyecto próximo a completarse';
      } else if (project.progress >= 0.5) {
        updateType = 'Actualización';
        updateDescription = 'Nuevos avances en el proyecto';
      } else if (project.progress >= 0.2) {
        updateType = 'Inicio';
        updateDescription = 'Proyecto iniciado recientemente';
      } else {
        updateType = 'Actualización';
        updateDescription = 'Planificación en progreso';
      }

      recentUpdates.add({
        'projectName': project.name,
        'updateType': updateType,
        'description': updateDescription,
        'date': Formatters.formatDate(updateDate),
        'progress': project.progress,
        'status': project.status,
        'clientName': project.clientName,
        'completedPercentage': Formatters.formatPercentage(project.progress),
      });
    }

    return recentUpdates;
  }
}