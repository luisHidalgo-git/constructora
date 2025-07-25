import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../widgets/custom_file_picker.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import '../services/image_service.dart';
import '../services/sync_service.dart';
import '../features/projects/widgets/project_form_fields.dart';
import '../features/projects/widgets/project_update_fields.dart';
import '../features/projects/utils/project_utils.dart';
import '../core/utils/validators.dart';
import '../widgets/project_gallery_widget.dart';
import '../models/project_image_model.dart';
import '../services/project_image_service.dart';

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
  List<ProjectImageModel> _projectImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _loadProjectData();
    } else {
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
    _loadProjectImages();
  }

  Future<void> _loadProjectImages() async {
    if (widget.project != null) {
      try {
        print(
          '🔍 UpdateProjectScreen - Loading project images for: ${widget.project!.id}',
        );
        final images = await ProjectImageService.getProjectImages(
          widget.project!.id,
        );
        setState(() {
          _projectImages = images;
        });
        print('✅ UpdateProjectScreen - Loaded ${images.length} project images');
      } catch (e) {
        print('Error loading project images: $e');
        setState(() {
          _projectImages = [];
        });
      }
    }
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

    if (isUpdate || !_hasUnsavedChanges) {
      return true;
    }

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
        ) ??
        false;
  }

  Widget _buildRequiredFieldsInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Los campos marcados con (*) son obligatorios',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
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
    ProjectUtils.updateProgressProportionally(
      newProgress: newProgress,
      originalProject: widget.project,
      setProgress: (progress) => setState(() => _projectProgress = progress),
      setIndicators: (indicators) =>
          setState(() => _keyIndicators = indicators),
      setStatus: (status) => setState(() => _projectStatus = status),
      currentIndicators: _keyIndicators,
    );
  }

  void _updateStatusProportionally(String newStatus) {
    ProjectUtils.updateStatusProportionally(
      newStatus: newStatus,
      currentProgress: _projectProgress,
      originalProject: widget.project,
      setProgress: (progress) => setState(() => _projectProgress = progress),
      setIndicators: (indicators) =>
          setState(() => _keyIndicators = indicators),
      setStatus: (status) => setState(() => _projectStatus = status),
      currentIndicators: _keyIndicators,
    );
  }

  void _updateIndicatorsProportionally(Map<String, double> newIndicators) {
    ProjectUtils.updateIndicatorsProportionally(
      newIndicators: newIndicators,
      currentProgress: _projectProgress,
      setProgress: (progress) => setState(() => _projectProgress = progress),
      setIndicators: (indicators) =>
          setState(() => _keyIndicators = indicators),
    );
  }

  String? _validateFields() {
    final missingFields = ProjectUtils.validateProjectFields(
      projectName: _projectNameController.text,
      clientName: _clientNameController.text,
      description: _projectManagerController.text,
      location: _locationController.text,
      budget: _budgetController.text,
      startDate: _startDateController.text,
      endDate: _endDateController.text,
    );

    return ProjectUtils.getValidationErrorMessage(missingFields);
  }

  Future<void> _updateProject() async {
    String? validationError = _validateFields();
    if (validationError != null) {
      _showMessage(validationError, isError: true);
      return;
    }

    if (_selectedImagePath != null &&
        ImageService.isLocalImage(_selectedImagePath!)) {
      _showMessage(
        'ERROR: La imagen debe estar guardada en el servidor. Por favor, selecciona la imagen nuevamente y espera a que se suba completamente.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl = _selectedImagePath ?? widget.project?.imageUrl ?? '';

      String processedImageUrl;
      try {
        processedImageUrl = await ImageService.processImageForProject(imageUrl);
      } catch (e) {
        if (imageUrl.isNotEmpty && ImageService.isLocalImage(imageUrl)) {
          throw Exception(
            'No se puede crear el proyecto: Error subiendo imagen. ${e.toString()}',
          );
        }
        processedImageUrl =
            'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800';
      }

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
        imageUrl: processedImageUrl,
      );

      ProjectModel result;
      if (widget.project != null) {
        result = await ProjectService.updateProject(
          widget.project!.id,
          projectData,
        );
        await SyncService.projectUpdated(result.toUpdateJson());
        _showMessage('Proyecto actualizado exitosamente');
      } else {
        result = await ProjectService.createProject(projectData);
        await SyncService.projectCreated(result.toUpdateJson());
        _showMessage('Proyecto creado exitosamente');
        setState(() {
          _hasUnsavedChanges = false;
        });
      }

      Navigator.pop(context, result);
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('imagen debe estar en el servidor')) {
        _showMessage(
          'ERROR CRÍTICO: Para usar la app en múltiples dispositivos, todas las imágenes deben guardarse en el servidor. Por favor, selecciona la imagen nuevamente.',
          isError: true,
        );
      } else {
        _showMessage('Error: ${e.toString()}', isError: true);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              _buildHeader(isUpdate),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProjectFormFields(
                        projectNameController: _projectNameController,
                        clientNameController: _clientNameController,
                        descriptionController: _projectManagerController,
                        locationController: _locationController,
                        budgetController: _budgetController,
                        startDateController: _startDateController,
                        endDateController: _endDateController,
                        onFieldChanged: _onFieldChanged,
                      ),
                      if (isUpdate) ...[
                        const SizedBox(height: 32),
                        ProjectUpdateFields(
                          progress: _projectProgress,
                          status: _projectStatus,
                          keyIndicators: _keyIndicators,
                          notesController: _notesController,
                          onProgressChanged: _updateProgressProportionally,
                          onStatusChanged: _updateStatusProportionally,
                          onIndicatorsChanged: _updateIndicatorsProportionally,
                        ),

                        const SizedBox(height: 24),

                        // Galería de imágenes para proyectos existentes
                        Text(
                          'Galería de Imágenes del Proyecto',
                          style: AppTextStyles.fieldLabel.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ProjectGalleryWidget(
                          projectId: widget.project!.id,
                          initialImages:
                              const [], // No pasar imágenes iniciales para forzar carga del servidor
                          onImagesChanged: (images) {
                            print(
                              '🔍 UpdateProjectScreen - Received images update: ${images.length} images',
                            );
                            setState(() {
                              _projectImages = images;
                            });
                            print(
                              '✅ UpdateProjectScreen - Project images updated in state: ${images.length} images',
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Las imágenes de la galería se mostrarán en los detalles del proyecto como evidencia de avances.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isUpdate) ...[
                        const SizedBox(height: 32),
                        CustomFilePicker(
                          initialImagePath: _selectedImagePath,
                          onImageSelected: (imagePath) {
                            print(
                              '🔍 Image selected in UpdateProjectScreen: $imagePath',
                            );
                            setState(() {
                              _selectedImagePath = imagePath;
                            });
                            _onFieldChanged();
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildRequiredFieldsInfo(),
                      ],
                      const SizedBox(height: 40),
                      _buildActionButton(isUpdate),
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

  Widget _buildHeader(bool isUpdate) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop) {
                // Determinar a dónde regresar y enviar evento apropiado
                if (widget.project != null) {
                  // Si estamos editando, regresar a detalle del proyecto
                  SyncService.setCurrentScreen('project_detail');
                  SyncService.setCurrentProjectId(widget.project!.id);
                  SyncService.navigateToProjectDetail(widget.project!.id);
                } else {
                  // Si estamos creando, regresar a home
                  SyncService.setCurrentScreen('home');
                  SyncService.navigateToHome();
                }
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  // Fallback a home si no se puede hacer pop
                  SyncService.setCurrentScreen('home');
                  SyncService.navigateToHome();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
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
    );
  }

  Widget _buildActionButton(bool isUpdate) {
    return SizedBox(
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
                isUpdate ? 'Enviar Actualización' : 'Crear Proyecto',
                style: AppTextStyles.buttonText,
              ),
      ),
    );
  }
}
