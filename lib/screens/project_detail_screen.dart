import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../models/project_model.dart';
import '../models/project_image_model.dart';
import '../services/project_image_service.dart';
import '../core/utils/image_utils.dart';
import '../core/utils/color_utils.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/error_widget.dart';
import '../widgets/project_gallery_widget.dart';
import '../screens/update_project_screen.dart';
import '../services/sync_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  List<ProjectImageModel> _projectImages = [];
  bool _isLoadingImages = true;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    _loadProjectImages();
    _sendNavigationEvent();
  }

  Future<void> _sendNavigationEvent() async {
    await SyncService.navigateToProjectDetail(widget.project.id);
    print(
      '📱 Mobile: Sent navigate_to_project_detail event for: ${widget.project.id}',
    );
  }

  Future<void> _loadProjectImages() async {
    setState(() {
      _isLoadingImages = true;
      _imageError = null;
    });

    try {
      final images = await ProjectImageService.getProjectImages(
        widget.project.id,
      );
      setState(() {
        _projectImages = images;
        _isLoadingImages = false;
      });
      print('✅ Loaded ${images.length} images for project detail');
    } catch (e) {
      print('Error loading project images: $e');
      setState(() {
        _projectImages = [];
        _isLoadingImages = false;
        _imageError = e.toString();
      });
    }
  }

  Future<void> _refreshImages() async {
    await _loadProjectImages();
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateProjectScreen(project: widget.project),
      ),
    );

    if (result != null) {
      // Actualizar imágenes después de editar
      _refreshImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProjectImage(),
                    const SizedBox(height: 24),
                    _buildProjectInfo(),
                    const SizedBox(height: 24),
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                    _buildKeyIndicatorsSection(),
                    const SizedBox(height: 24),
                    _buildProjectGallerySection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 1),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
              'Detalle del Proyecto',
              style: AppTextStyles.header.copyWith(fontSize: 20),
            ),
          ),
          GestureDetector(
            onTap: _navigateToEdit,
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
                Icons.edit,
                color: AppColors.iconGray,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        image: ImageUtils.buildImageProvider(widget.project.imageUrl) != null
            ? DecorationImage(
                image: ImageUtils.buildImageProvider(widget.project.imageUrl)!,
                fit: BoxFit.cover,
              )
            : null,
        color: ImageUtils.buildImageProvider(widget.project.imageUrl) == null
            ? Colors.grey[300]
            : null,
      ),
      child: ImageUtils.buildImageProvider(widget.project.imageUrl) == null
          ? const Center(
              child: Icon(Icons.image_outlined, color: Colors.grey, size: 60),
            )
          : Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ColorUtils.getStatusColor(
                        widget.project.status,
                      ).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.project.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProjectInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.project.name,
            style: AppTextStyles.header.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Cliente: ${widget.project.clientName}',
            style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Descripción', widget.project.description),
          const SizedBox(height: 12),
          _buildInfoRow('Ubicación', widget.project.location),
          const SizedBox(height: 12),
          _buildInfoRow('Presupuesto', widget.project.budget),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow('Inicio', widget.project.startDate),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildInfoRow('Fin', widget.project.endDate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.subtitle.copyWith(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso del Proyecto',
                style: AppTextStyles.fieldLabel.copyWith(fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ColorUtils.getProgressColor(
                    widget.project.progress,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(widget.project.progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorUtils.getProgressColor(widget.project.progress),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: widget.project.progress,
            minHeight: 12,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              ColorUtils.getProgressColor(widget.project.progress),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyIndicatorsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Indicadores Clave',
            style: AppTextStyles.fieldLabel.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
          // Usar Column en lugar de GridView para evitar overflow
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildIndicatorCard(
                      'Calidad',
                      widget.project.keyIndicators['Calidad'] ?? 0.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildIndicatorCard(
                      'Tiempo',
                      widget.project.keyIndicators['Tiempo'] ?? 0.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildIndicatorCard(
                      'Presupuesto',
                      widget.project.keyIndicators['Presupuesto'] ?? 0.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildIndicatorCard(
                      'Satisfacción',
                      widget.project.keyIndicators['Satisfacción'] ?? 0.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(String label, double value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorUtils.getIndicatorColorByName(label).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorUtils.getIndicatorColorByName(label).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ColorUtils.getIndicatorColorByName(label),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(value * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectGallerySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Galería de Avances',
                style: AppTextStyles.fieldLabel.copyWith(fontSize: 16),
              ),
              if (_projectImages.isNotEmpty)
                Text(
                  '${_projectImages.length} ${_projectImages.length == 1 ? 'imagen' : 'imágenes'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGalleryContent(),
        ],
      ),
    );
  }

  Widget _buildGalleryContent() {
    if (_isLoadingImages) {
      return Container(
        height: 120,
        child: const Center(
          child: LoadingWidget(message: 'Cargando galería...'),
        ),
      );
    }

    if (_imageError != null) {
      return Container(
        height: 120,
        child: CustomErrorWidget(
          title: 'Error al cargar galería',
          message: _imageError!,
          onRetry: _refreshImages,
          icon: Icons.photo_library_outlined,
        ),
      );
    }

    if (_projectImages.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                color: Colors.grey[400],
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'No hay imágenes de avances',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Las imágenes aparecerán aquí cuando se agreguen desde la edición',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Grid de imágenes
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _projectImages.length,
          itemBuilder: (context, index) {
            final image = _projectImages[index];
            return GestureDetector(
              onTap: () => _showImageViewer(index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  image: ImageUtils.buildImageProvider(image.imageUrl) != null
                      ? DecorationImage(
                          image: ImageUtils.buildImageProvider(image.imageUrl)!,
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: ImageUtils.buildImageProvider(image.imageUrl) == null
                      ? Colors.grey[300]
                      : null,
                ),
                child: ImageUtils.buildImageProvider(image.imageUrl) == null
                    ? const Icon(
                        Icons.image_outlined,
                        color: Colors.grey,
                        size: 30,
                      )
                    : Stack(
                        children: [
                          // Overlay con número de imagen
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),

        if (_projectImages.length > 6) ...[
          const SizedBox(height: 12),
          Text(
            'Mostrando ${_projectImages.length} imágenes de avances del proyecto',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  void _showImageViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectImageViewer(
          images: _projectImages,
          initialIndex: initialIndex,
          onImageDeleted: (imageId) {
            setState(() {
              _projectImages.removeWhere((img) => img.id == imageId);
            });
          },
        ),
      ),
    );
  }
}
