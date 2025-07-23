import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../widgets/project_detail_card.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/project_service.dart';
import '../models/project_model.dart';
import '../screens/update_project_screen.dart';
import 'dart:io';
import '../services/image_service.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<ProjectModel> _projects = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    // Iniciar sincronización y enviar evento de navegación a proyectos
    _initSync();
  }

  Future<void> _initSync() async {
    try {
      final user = await AuthService.getSavedUser();
      if (user != null) {
        await SyncService.startSync(user.id);
        await SyncService.navigateToProjects();
      }
    } catch (e) {
      print('Error initializing sync: $e');
    }
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final projects = await ProjectService.getProjects();
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _projects = []; // Mantener vacío si no hay datos
        _isLoading = false;
        // No mostrar error si simplemente no hay datos
      });
    }
  }

  Future<void> _refreshProjects() async {
    await _loadProjects();
  }

  void _showProjectDetails(ProjectModel project) {
    // CRÍTICO: Enviar evento de navegación a detalle de proyecto ANTES de mostrar el diálogo
    SyncService.navigateToProjectDetail(project.id);
    print('📱 Mobile: Sent navigate_to_project_detail event for project: ${project.id}');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: AppTextStyles.header.copyWith(fontSize: 20),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Enviar evento de regreso a proyectos cuando se cierre el diálogo
                        SyncService.navigateToProjects();
                        print('📱 Mobile: Sent navigate_to_projects event (dialog closed)');
                      },
                      icon: const Icon(Icons.close, color: AppColors.iconGray),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Project Image
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: _buildImageProvider(project.imageUrl) != null
                        ? DecorationImage(
                            image: _buildImageProvider(project.imageUrl)!,
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: _buildImageProvider(project.imageUrl) == null
                        ? Colors.grey[300]
                        : null,
                  ),
                  child: _buildImageProvider(project.imageUrl) == null
                      ? const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.grey,
                            size: 60,
                          ),
                        )
                      : null,
                ),

                const SizedBox(height: 20),

                // Project Details
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Cliente', project.clientName),
                        const SizedBox(height: 12),
                        _buildDetailRow('Descripción', project.description),
                        const SizedBox(height: 12),
                        _buildDetailRow('Ubicación', project.location),
                        const SizedBox(height: 12),
                        _buildDetailRow('Presupuesto', project.budget),
                        const SizedBox(height: 12),
                        _buildDetailRow('Fecha de Inicio', project.startDate),
                        const SizedBox(height: 12),
                        _buildDetailRow('Fecha de Fin', project.endDate),
                        const SizedBox(height: 12),
                        _buildDetailRow('Estado', project.status),
                        const SizedBox(height: 16),

                        // Progress
                        Text(
                          'Progreso',
                          style: AppTextStyles.fieldLabel.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: project.progress,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getProgressColor(project.progress),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(project.progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Key Indicators
                        Text(
                          'Indicadores Clave',
                          style: AppTextStyles.fieldLabel.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...project.keyIndicators.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGray,
                                  ),
                                ),
                                Text(
                                  '${(entry.value * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getIndicatorColor(entry.value),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel.copyWith(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
      ],
    );
  }

  ImageProvider? _buildImageProvider(String imageUrl) {
    try {
      if (imageUrl.isEmpty) {
        return null;
      }

      // Si es una URL de internet
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return NetworkImage(imageUrl);
      }

      // Si es un archivo local
      if (imageUrl.startsWith('file://') || imageUrl.startsWith('/')) {
        String filePath = imageUrl.startsWith('file://')
            ? imageUrl.substring(7)
            : imageUrl;
        File file = File(filePath);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }

      // Si es una ruta del servidor sin dominio, construir URL completa
      if (imageUrl.startsWith('/uploads/')) {
        final fullUrl = ImageService.buildServerImageUrl(imageUrl);
        return NetworkImage(fullUrl);
      }

      // Si parece ser un nombre de archivo, intentar construir URL del servidor
      if (!imageUrl.contains('/') &&
          (imageUrl.contains('.jpg') ||
              imageUrl.contains('.png') ||
              imageUrl.contains('.jpeg'))) {
        final fullUrl = ImageService.buildServerImageUrl('/uploads/$imageUrl');
        return NetworkImage(fullUrl);
      }

      return const NetworkImage(
        'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800',
      );
    } catch (e) {
      return const NetworkImage(
        'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800',
      );
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.7) {
      return const Color(0xFF10B981);
    } else if (progress >= 0.4) {
      return const Color(0xFF3B82F6);
    } else {
      return const Color(0xFFEF4444);
    }
  }

  Color _getIndicatorColor(double value) {
    if (value >= 0.8) {
      return const Color(0xFF10B981);
    } else if (value >= 0.6) {
      return const Color(0xFF3B82F6);
    } else if (value >= 0.4) {
      return const Color(0xFFFF9500);
    } else {
      return const Color(0xFFEF4444);
    }
  }

  void _showProjectOptions(ProjectModel project) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                project.name,
                style: AppTextStyles.header.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              // Actualizar
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Actualizar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                subtitle: const Text(
                  'Editar información del proyecto',
                  style: TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UpdateProjectScreen(project: project),
                    ),
                  ).then((result) {
                    if (result != null) {
                      _refreshProjects();
                    }
                  });
                },
              ),

              const SizedBox(height: 8),

              // Eliminar
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                ),
                title: const Text(
                  'Eliminar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                subtitle: const Text(
                  'Borrar proyecto permanentemente',
                  style: TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteProject(project);
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteProject(ProjectModel project) {
    showDialog(
      context: context,
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_outlined,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Eliminar Proyecto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que deseas eliminar el proyecto "${project.name}"?',
                style: const TextStyle(fontSize: 16, color: AppColors.textGray),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción no se puede deshacer.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteProject(project);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProject(ProjectModel project) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      // Eliminar del servidor
      final success = await ProjectService.deleteProject(project.id);

      if (mounted && success) {
        Navigator.pop(context); // Cerrar loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Proyecto "${project.name}" eliminado exitosamente'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Actualizar la lista
        _refreshProjects();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
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
                      'Mis Proyectos',
                      style: AppTextStyles.header.copyWith(fontSize: 20),
                    ),
                  ),
                  GestureDetector(
                    onTap: _refreshProjects,
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
                        Icons.refresh,
                        color: AppColors.iconGray,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Projects List
            Expanded(child: _buildProjectsList()),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 1),
    );
  }

  Widget _buildProjectsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar proyectos',
              style: AppTextStyles.header.copyWith(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshProjects,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay proyectos',
              style: AppTextStyles.header.copyWith(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer proyecto para comenzar',
              style: AppTextStyles.subtitle,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshProjects,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        children: [
          ..._projects
              .map(
                (project) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ProjectDetailCard(
                    project: project,
                    title: project.name,
                    location: project.location,
                    date: project.startDate,
                    progress: project.progress,
                    status: project.status,
                    budget: project.budget,
                    imageUrl: project.imageUrl,
                    onTap: () => _showProjectDetails(project),
                    onLongPress: () => _showProjectOptions(project),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}