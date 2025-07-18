import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_date_field.dart';
import '../widgets/custom_budget_field.dart';
import '../widgets/custom_file_picker.dart';
import '../widgets/location_picker_widget.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/status_selector.dart';
import '../widgets/key_indicators_widget.dart';
import '../widgets/update_notes_widget.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

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
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _loadProjectData();
    } else {
      // Para proyectos nuevos, detectar cambios
      _setupChangeListeners();
    }
  }

  void _setupChangeListeners() {
    _projectNameController.addListener(_onFieldChanged);
    _clientNameController.addListener(_onFieldChanged);
    _projectManagerController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);
    _budgetController.addListener(_onFieldChanged);
    _startDateController.addListener(_onFieldChanged);
    _endDateController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
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
    _selectedImagePath = project.imageUrl;
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

  Future<bool> _onWillPop() async {
    final isUpdate = widget.project != null;
    
    // Si es actualización o no hay cambios, permitir salir
    if (isUpdate || !_hasUnsavedChanges) {
      return true;
    }

    // Si es creación y hay cambios, mostrar confirmación
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_outlined,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Salir sin guardar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas salir? Se perderán todos los cambios realizados.',
            style: TextStyle(fontSize: 16, color: AppColors.textGray),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Continuar editando',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Salir sin guardar',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _updateProject() async {
    // Validación mejorada con mensajes específicos
    String? validationError = _validateFields();
    if (validationError != null) {
      _showMessage(validationError, isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final projectData = ProjectModel(
        id: widget.project?.id ?? '',
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
        imageUrl: _selectedImagePath ?? 
            widget.project?.imageUrl ??
            'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800',
      );

      ProjectModel result;
      if (widget.project != null) {
        // Actualizar proyecto existente
        result = await ProjectService.updateProject(
          widget.project!.id,
          projectData,
        );
        _showMessage('Proyecto actualizado exitosamente');
      } else {
        // Crear nuevo proyecto
        result = await ProjectService.createProject(projectData);
        _showMessage('Proyecto creado exitosamente');
        // Marcar como guardado
        setState(() {
          _hasUnsavedChanges = false;
        });
      }

      Navigator.pop(context, result);
    } catch (e) {
      _showMessage('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _validateFields() {
    List<String> missingFields = [];

    if (_projectNameController.text.trim().isEmpty) {
      missingFields.add('Nombre del proyecto');
    }
    if (_clientNameController.text.trim().isEmpty) {
      missingFields.add('Nombre del cliente');
    }
    if (_projectManagerController.text.trim().isEmpty) {
      missingFields.add('Descripción del proyecto');
    }
    if (_locationController.text.trim().isEmpty) {
      missingFields.add('Ubicación');
    }
    if (_budgetController.text.trim().isEmpty) {
      missingFields.add('Presupuesto');
    }
    if (_startDateController.text.trim().isEmpty) {
      missingFields.add('Fecha de inicio');
    }
    if (_endDateController.text.trim().isEmpty) {
      missingFields.add('Fecha de fin');
    }

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

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                    onTap: () async {
                      final shouldPop = await _onWillPop();
                      if (shouldPop) {
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
                    LocationPickerWidget(
                      initialLocation: _locationController.text,
                      onLocationSelected: (location) {
                        setState(() {
                          _locationController.text = location;
                          _onFieldChanged();
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Total Budget
                    Text(
                      'Presupuesto Total',
                      style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CustomBudgetField(
                      controller: _budgetController,
                      hintText: '2,500,000',
                      onChanged: _onFieldChanged,
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
                                onChanged: _onFieldChanged,
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
                                onChanged: _onFieldChanged,
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
                      CustomFilePicker(
                        initialImagePath: _selectedImagePath,
                        onImageSelected: (imagePath) {
                          setState(() {
                            _selectedImagePath = imagePath;
                          });
                          _onFieldChanged();
                        },
                      ),

                      const SizedBox(height: 16),

                      // Campos obligatorios info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Los campos marcados con (*) son obligatorios',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isUpdate
                                    ? 'Enviar Actualización'
                                    : 'Crear Proyecto',
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
      ),
    );
  }
}
