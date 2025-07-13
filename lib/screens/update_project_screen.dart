import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_date_field.dart';
import '../widgets/custom_file_picker.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/status_selector.dart';
import '../widgets/key_indicators_widget.dart';
import '../widgets/update_notes_widget.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../models/project_model.dart';

class UpdateProjectScreen extends StatefulWidget {
  final ProjectModel? project;

  const UpdateProjectScreen({super.key, this.project});

  @override
  State<UpdateProjectScreen> createState() => _UpdateProjectScreenState();
}

class _UpdateProjectScreenState extends State<UpdateProjectScreen> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _projectManagerController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double _projectProgress = 0.0;
  String _projectStatus = 'Activo';
  Map<String, double> _keyIndicators = {
    'Calidad': 0.0,
    'Tiempo': 0.0,
    'Presupuesto': 0.0,
    'Satisfacción': 0.0,
  };

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _loadProjectData();
    }
  }

  void _loadProjectData() {
    final project = widget.project!;
    _projectNameController.text = project.name;
    _clientNameController.text = project.clientName;
    _projectManagerController.text = project.description;
    _locationController.text = project.location;
    _budgetController.text = project.budget;
    _startDateController.text = project.startDate;
    _endDateController.text = project.endDate;
    _projectProgress = project.progress;
    _projectStatus = project.status;
    _keyIndicators = Map.from(project.keyIndicators);
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _clientNameController.dispose();
    _projectManagerController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateProject() {
    // Here you would typically save to a database or state management
    final updatedProject = ProjectModel(
      id:
          widget.project?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _projectNameController.text,
      clientName: _clientNameController.text,
      description: _projectManagerController.text,
      location: _locationController.text,
      budget: _budgetController.text,
      startDate: _startDateController.text,
      endDate: _endDateController.text,
      progress: _projectProgress,
      status: _projectStatus,
      keyIndicators: _keyIndicators,
      imageUrl:
          widget.project?.imageUrl ??
          'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800',
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.project != null
              ? 'Proyecto actualizado exitosamente'
              : 'Proyecto creado exitosamente',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context, updatedProject);
  }

  void _updateProgressProportionally(double newProgress) {
    setState(() {
      _projectProgress = newProgress;

      // Actualizar indicadores clave proporcionalmente basándose en el progreso general
      final progressFactor = newProgress;
      _keyIndicators = _keyIndicators.map((key, value) {
        // Mantener la relación proporcional pero ajustar según el progreso general
        double baseValue = widget.project?.keyIndicators[key] ?? 0.5;
        double adjustedValue = (baseValue * 0.7) + (progressFactor * 0.3);
        return MapEntry(key, adjustedValue.clamp(0.0, 1.0));
      });

      // Actualizar estado basándose en el progreso
      if (newProgress >= 0.95) {
        _projectStatus = 'Completado';
      } else if (newProgress >= 0.8) {
        _projectStatus = 'Activo';
      } else if (newProgress < 0.1) {
        _projectStatus = 'Pausado';
      }
    });
  }

  void _updateStatusProportionally(String newStatus) {
    setState(() {
      _projectStatus = newStatus;

      // Ajustar progreso basándose en el estado
      switch (newStatus) {
        case 'Completado':
          if (_projectProgress < 0.95) {
            _projectProgress = 1.0;
            _updateIndicatorsBasedOnProgress(1.0);
          }
          break;
        case 'Pausado':
          if (_projectProgress > 0.3) {
            _projectProgress = (_projectProgress * 0.7).clamp(0.0, 0.3);
            _updateIndicatorsBasedOnProgress(_projectProgress);
          }
          break;
        case 'Cancelado':
          // No cambiar progreso automáticamente para cancelado
          break;
        case 'Activo':
          if (_projectProgress < 0.1) {
            _projectProgress = 0.2;
            _updateIndicatorsBasedOnProgress(0.2);
          }
          break;
      }
    });
  }

  void _updateIndicatorsBasedOnProgress(double progress) {
    _keyIndicators = _keyIndicators.map((key, value) {
      double baseValue = widget.project?.keyIndicators[key] ?? 0.5;
      double adjustedValue = (baseValue * 0.7) + (progress * 0.3);
      return MapEntry(key, adjustedValue.clamp(0.0, 1.0));
    });
  }

  void _updateIndicatorsProportionally(Map<String, double> newIndicators) {
    setState(() {
      _keyIndicators = newIndicators;

      // Calcular progreso promedio basándose en indicadores
      double averageIndicator =
          newIndicators.values.reduce((a, b) => a + b) / newIndicators.length;

      // Ajustar progreso general si la diferencia es significativa
      if ((averageIndicator - _projectProgress).abs() > 0.2) {
        _projectProgress = ((_projectProgress * 0.6) + (averageIndicator * 0.4))
            .clamp(0.0, 1.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.project != null;

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
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
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
                      isUpdate ? 'Actualizar Proyecto' : 'Crear Proyecto',
                      style: AppTextStyles.header.copyWith(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Name
                    Text(
                      'Nombre del proyecto',
                      style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _projectNameController,
                      hintText: 'Complejo Industrial Norte',
                    ),

                    const SizedBox(height: 24),

                    // Client Name
                    Text(
                      'Nombre del cliente',
                      style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _clientNameController,
                      hintText: 'Ej. Manufactura Industrial SAC',
                    ),

                    const SizedBox(height: 24),

                    // Project Description
                    Text(
                      'Descripción del proyecto',
                      style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _projectManagerController,
                      hintText: 'Ej. Una breve descripción del proyecto...',
                    ),

                    const SizedBox(height: 24),

                    // Location
                    Text(
                      'Ubicación',
                      style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _locationController,
                      hintText: 'Ej. Santiago Papasquiero',
                    ),

                    const SizedBox(height: 24),

                    // Total Budget
                    Text(
                      'Presupuesto Total',
                      style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _budgetController,
                      hintText: '\$2,500,000',
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 24),

                    // Date Fields
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha de Inicio',
                                style: AppTextStyles.fieldLabel.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CustomDateField(
                                controller: _startDateController,
                                hintText: 'dd/mm/aaaa',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha de Fin',
                                style: AppTextStyles.fieldLabel.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CustomDateField(
                                controller: _endDateController,
                                hintText: 'dd/mm/aaaa',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (isUpdate) ...[
                      const SizedBox(height: 32),

                      // Project Progress
                      ProgressIndicatorWidget(
                        progress: _projectProgress,
                        onProgressChanged: _updateProgressProportionally,
                      ),

                      const SizedBox(height: 24),

                      // Project Status
                      StatusSelector(
                        currentStatus: _projectStatus,
                        onStatusChanged: _updateStatusProportionally,
                      ),

                      const SizedBox(height: 24),

                      // Key Indicators
                      KeyIndicatorsWidget(
                        indicators: _keyIndicators,
                        onIndicatorsChanged: _updateIndicatorsProportionally,
                      ),

                      const SizedBox(height: 24),

                      // Update Notes
                      UpdateNotesWidget(controller: _notesController),
                    ],

                    if (!isUpdate) ...[
                      const SizedBox(height: 32),

                      // File Picker
                      const CustomFilePicker(),
                    ],

                    const SizedBox(height: 40),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updateProject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          isUpdate ? 'Enviar Actualización' : 'Crear Proyecto',
                          style: AppTextStyles.buttonText,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
