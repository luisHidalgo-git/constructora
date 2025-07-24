import '../../../models/project_model.dart';
import '../../../core/constants/app_constants.dart';

class ProjectUtils {
  static void updateProgressProportionally({
    required double newProgress,
    required ProjectModel? originalProject,
    required Function(double) setProgress,
    required Function(Map<String, double>) setIndicators,
    required Function(String) setStatus,
    required Map<String, double> currentIndicators,
  }) {
    setProgress(newProgress);

    // Actualizar indicadores clave proporcionalmente basándose en el progreso general
    final progressFactor = newProgress;
    final updatedIndicators = currentIndicators.map((key, value) {
      // Mantener la relación proporcional pero ajustar según el progreso general
      double baseValue = originalProject?.keyIndicators[key] ?? 0.5;
      double adjustedValue = (baseValue * 0.7) + (progressFactor * 0.3);
      return MapEntry(key, adjustedValue.clamp(0.0, 1.0));
    });
    setIndicators(updatedIndicators);

    // Actualizar estado basándose en el progreso
    if (newProgress >= 0.95) {
      setStatus('Completado');
    } else if (newProgress >= 0.8) {
      setStatus('Activo');
    } else if (newProgress < 0.1) {
      setStatus('Pausado');
    }
  }

  static void updateStatusProportionally({
    required String newStatus,
    required double currentProgress,
    required ProjectModel? originalProject,
    required Function(double) setProgress,
    required Function(Map<String, double>) setIndicators,
    required Function(String) setStatus,
    required Map<String, double> currentIndicators,
  }) {
    setStatus(newStatus);

    double newProgress = currentProgress;
    
    // Ajustar progreso basándose en el estado
    switch (newStatus) {
      case 'Completado':
        if (currentProgress < 0.95) {
          newProgress = 1.0;
        }
        break;
      case 'Pausado':
        if (currentProgress > 0.3) {
          newProgress = (currentProgress * 0.7).clamp(0.0, 0.3);
        }
        break;
      case 'Cancelado':
        // No cambiar progreso automáticamente para cancelado
        break;
      case 'Activo':
        if (currentProgress < 0.1) {
          newProgress = 0.2;
        }
        break;
    }
    
    if (newProgress != currentProgress) {
      setProgress(newProgress);
      _updateIndicatorsBasedOnProgress(
        newProgress,
        originalProject,
        setIndicators,
        currentIndicators,
      );
    }
  }

  static void updateIndicatorsProportionally({
    required Map<String, double> newIndicators,
    required double currentProgress,
    required Function(double) setProgress,
    required Function(Map<String, double>) setIndicators,
  }) {
    setIndicators(newIndicators);

    // Calcular progreso promedio basándose en indicadores
    double averageIndicator =
        newIndicators.values.reduce((a, b) => a + b) / newIndicators.length;

    // Ajustar progreso general si la diferencia es significativa
    if ((averageIndicator - currentProgress).abs() > 0.2) {
      final newProgress = ((currentProgress * 0.6) + (averageIndicator * 0.4))
          .clamp(0.0, 1.0);
      setProgress(newProgress);
    }
  }

  static void _updateIndicatorsBasedOnProgress(
    double progress,
    ProjectModel? originalProject,
    Function(Map<String, double>) setIndicators,
    Map<String, double> currentIndicators,
  ) {
    final updatedIndicators = currentIndicators.map((key, value) {
      double baseValue = originalProject?.keyIndicators[key] ?? 0.5;
      double adjustedValue = (baseValue * 0.7) + (progress * 0.3);
      return MapEntry(key, adjustedValue.clamp(0.0, 1.0));
    });
    setIndicators(updatedIndicators);
  }

  static List<String> validateProjectFields({
    required String projectName,
    required String clientName,
    required String description,
    required String location,
    required String budget,
    required String startDate,
    required String endDate,
  }) {
    List<String> missingFields = [];

    if (projectName.trim().isEmpty) {
      missingFields.add('Nombre del proyecto');
    }
    if (clientName.trim().isEmpty) {
      missingFields.add('Nombre del cliente');
    }
    if (description.trim().isEmpty) {
      missingFields.add('Descripción del proyecto');
    }
    if (location.trim().isEmpty) {
      missingFields.add('Ubicación');
    }
    if (budget.trim().isEmpty) {
      missingFields.add('Presupuesto');
    }
    if (startDate.trim().isEmpty) {
      missingFields.add('Fecha de inicio');
    }
    if (endDate.trim().isEmpty) {
      missingFields.add('Fecha de fin');
    }

    return missingFields;
  }

  static String? getValidationErrorMessage(List<String> missingFields) {
    if (missingFields.isEmpty) {
      return null;
    }

    if (missingFields.length == 1) {
      return 'Por favor completa el campo: ${missingFields.first}';
    } else if (missingFields.length <= 3) {
      return 'Por favor completa los campos: ${missingFields.join(', ')}';
    } else {
      return 'Por favor completa todos los campos obligatorios (${missingFields.length} campos faltantes)';
    }
  }
}