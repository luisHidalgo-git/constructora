import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../models/project_image_model.dart';
import '../services/project_image_service.dart';
import '../core/utils/image_utils.dart';

class ProjectGalleryWidget extends StatefulWidget {
  final String projectId;
  final List<ProjectImageModel> initialImages;
  final Function(List<ProjectImageModel>)? onImagesChanged;

  const ProjectGalleryWidget({
    super.key,
    required this.projectId,
    this.initialImages = const [],
    this.onImagesChanged,
  });

  @override
  State<ProjectGalleryWidget> createState() => _ProjectGalleryWidgetState();
}

class _ProjectGalleryWidgetState extends State<ProjectGalleryWidget> {
  List<ProjectImageModel> _images = [];
  bool _isLoading = false;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
    print(
      '🔍 ProjectGalleryWidget - Initialized with ${_images.length} initial images',
    );
    if (_images.isEmpty) {
      print(
        '🔍 ProjectGalleryWidget - No initial images, loading from server...',
      );
      _loadImages();
    } else {
      print(
        '✅ ProjectGalleryWidget - Using ${_images.length} initial images from parent',
      );
    }
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final images = await ProjectImageService.getProjectImages(
        widget.projectId,
      );
      setState(() {
        _images = images;
        _isLoading = false;
      });

      // CRÍTICO: Notificar al widget padre sobre la carga inicial
      if (widget.onImagesChanged != null) {
        widget.onImagesChanged!(_images);
        print(
          '✅ ProjectGalleryWidget - Notified parent about loaded images: ${images.length} images',
        );
      }
    } catch (e) {
      print('Error loading project images: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.photos.request().isGranted) {
        return true;
      }
      if (await Permission.storage.request().isGranted) {
        return true;
      }
    } else if (Platform.isIOS) {
      if (await Permission.photos.request().isGranted) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _requestCameraPermission() async {
    return await Permission.camera.request().isGranted;
  }

  void _showImageSourceDialog() {
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_photo_alternate,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Agregar a Galería',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona una opción para agregar una nueva imagen a la galería del proyecto:',
                style: TextStyle(fontSize: 14, color: AppColors.textGray),
              ),
              const SizedBox(height: 20),

              // Camera Option
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _selectFromCamera();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tomar Foto',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Usar la cámara del dispositivo',
                              style: TextStyle(
                                fontSize: 12,
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

              const SizedBox(width: 12),

              // Gallery Option
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _selectFromGallery();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Elegir de Galería',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Seleccionar desde la galería',
                              style: TextStyle(
                                fontSize: 12,
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
          ],
        );
      },
    );
  }

  Future<void> _selectFromCamera() async {
    try {
      bool hasCameraPermission = await _requestCameraPermission();
      if (!hasCameraPermission) {
        _showMessage(
          'Se necesitan permisos de cámara para tomar fotos.',
          isError: true,
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        await _uploadImage(image.path);
      }
    } catch (e) {
      print('❌ Camera selection error: $e');
      _showMessage(
        'Error al tomar la foto. Verifica los permisos de cámara.',
        isError: true,
      );
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      bool hasGalleryPermission = await _requestPermissions();
      if (!hasGalleryPermission) {
        _showMessage(
          'Se necesitan permisos de galería para seleccionar fotos.',
          isError: true,
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadImage(image.path);
      }
    } catch (e) {
      print('❌ Gallery selection error: $e');
      _showMessage(
        'Error al seleccionar la imagen. Verifica los permisos de almacenamiento.',
        isError: true,
      );
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    setState(() {
      _isUploading = true;
    });

    try {
      print('🔍 Uploading image to project gallery...');

      final uploadedImage = await ProjectImageService.uploadProjectImage(
        projectId: widget.projectId,
        imagePath: imagePath,
      );

      setState(() {
        _images.insert(0, uploadedImage); // Agregar al inicio
        _isUploading = false;
      });

      // CRÍTICO: Notificar inmediatamente al widget padre sobre el cambio
      if (widget.onImagesChanged != null) {
        widget.onImagesChanged!(_images);
        print(
          '✅ ProjectGalleryWidget - Notified parent about new image: ${uploadedImage.id}',
        );
      }

      _showMessage('✅ Imagen agregada a la galería del proyecto');

      // Limpiar imagen local
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (e) {
        print('⚠️ Could not cleanup local image: $e');
      }
    } catch (e) {
      print('❌ Error uploading image to gallery: $e');
      setState(() {
        _isUploading = false;
      });
      _showMessage(
        'Error al subir la imagen a la galería: ${e.toString()}',
        isError: true,
      );
    }
  }

  void _showImageViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectImageViewer(
          images: _images,
          initialIndex: initialIndex,
          onImageDeleted: (imageId) {
            setState(() {
              _images.removeWhere((img) => img.id == imageId);
            });
            // CRÍTICO: Notificar al widget padre sobre la eliminación
            if (widget.onImagesChanged != null) {
              widget.onImagesChanged!(_images);
              print(
                '✅ ProjectGalleryWidget - Notified parent about image deletion: $imageId',
              );
            }
          },
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: !isError
            ? SnackBarAction(
                label: 'Ver Galería',
                textColor: Colors.white,
                onPressed: () {
                  // Acción opcional para ver la galería completa
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con botón de agregar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Galería del Proyecto',
              style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
            ),
            if (!_isUploading)
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Agregar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Galería de imágenes
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildGalleryContent(),
        ),
      ],
    );
  }

  Widget _buildGalleryContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_images.isEmpty && !_isUploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay imágenes en la galería',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca "Agregar" para subir la primera imagen',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      itemCount: _images.length + (_isUploading ? 1 : 0),
      itemBuilder: (context, index) {
        // Mostrar indicador de carga al final si se está subiendo
        if (_isUploading && index == _images.length) {
          return Container(
            width: 84,
            height: 84,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Subiendo...',
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final image = _images[index];
        return GestureDetector(
          onTap: () => _showImageViewer(index),
          child: Container(
            width: 84,
            height: 84,
            margin: const EdgeInsets.only(right: 8),
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
                ? const Icon(Icons.image_outlined, color: Colors.grey, size: 30)
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
    );
  }
}

class ProjectImageViewer extends StatefulWidget {
  final List<ProjectImageModel> images;
  final int initialIndex;
  final Function(String)? onImageDeleted;

  const ProjectImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    this.onImageDeleted,
  });

  @override
  State<ProjectImageViewer> createState() => _ProjectImageViewerState();
}

class _ProjectImageViewerState extends State<ProjectImageViewer> {
  late PageController _pageController;
  int _currentIndex = 0;
  late List<ProjectImageModel> _images;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _images = List.from(widget.images);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _deleteImage() {
    final currentImage = _images[_currentIndex];

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
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Eliminar Imagen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta imagen de la galería del proyecto?',
            style: TextStyle(fontSize: 16, color: AppColors.textGray),
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
                await _performDelete(currentImage);
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

  Future<void> _performDelete(ProjectImageModel image) async {
    try {
      final success = await ProjectImageService.deleteProjectImage(image.id);

      if (success) {
        // CRÍTICO: Actualizar la lista local inmediatamente
        setState(() {
          _images.removeWhere((img) => img.id == image.id);
        });

        // Notificar al widget padre
        if (widget.onImageDeleted != null) {
          widget.onImageDeleted!(image.id);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen eliminada de la galería'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Si era la última imagen, cerrar el visor
        if (_images.length <= 0) {
          Navigator.pop(context);
        } else {
          // Ajustar índice si es necesario
          if (_currentIndex >= _images.length) {
            setState(() {
              _currentIndex = _images.length - 1;
            });
            _pageController.animateToPage(
              _currentIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la imagen'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} de ${_images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteImage,
          ),
        ],
      ),
      body: Column(
        children: [
          // Visor de imagen principal
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final image = _images[index];
                return Center(
                  child: InteractiveViewer(
                    child: Container(
                      decoration: BoxDecoration(
                        image:
                            ImageUtils.buildImageProvider(image.imageUrl) !=
                                null
                            ? DecorationImage(
                                image: ImageUtils.buildImageProvider(
                                  image.imageUrl,
                                )!,
                                fit: BoxFit.contain,
                              )
                            : null,
                      ),
                      child:
                          ImageUtils.buildImageProvider(image.imageUrl) == null
                          ? const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.grey,
                                size: 100,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),

          // Información de la imagen
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_images[_currentIndex].description != null &&
                    _images[_currentIndex].description!.isNotEmpty)
                  Text(
                    _images[_currentIndex].description!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Subida: ${_formatDate(_images[_currentIndex].uploadedAt)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (_images[_currentIndex].uploadedBy != null)
                  Text(
                    'Por: ${_images[_currentIndex].uploadedBy!['name']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),

          // Thumbnails en la parte inferior
          if (_images.length > 1)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.black87,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  final image = _images[index];
                  final isSelected = index == _currentIndex;

                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                        image:
                            ImageUtils.buildImageProvider(image.imageUrl) !=
                                null
                            ? DecorationImage(
                                image: ImageUtils.buildImageProvider(
                                  image.imageUrl,
                                )!,
                                fit: BoxFit.cover,
                              )
                            : null,
                        color:
                            ImageUtils.buildImageProvider(image.imageUrl) ==
                                null
                            ? Colors.grey[700]
                            : null,
                      ),
                      child:
                          ImageUtils.buildImageProvider(image.imageUrl) == null
                          ? const Icon(
                              Icons.image_outlined,
                              color: Colors.grey,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
