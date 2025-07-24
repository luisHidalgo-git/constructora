import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/project_model.dart';
import '../services/activity_service.dart';
import '../models/activity_model.dart';
import 'tv_dashboard_screen.dart';
import '../services/sync_service.dart';
import 'dart:async';
import 'tv_qr_screen.dart';
import '../services/image_service.dart';

class TVProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;
  final Map<String, dynamic> user;

  const TVProjectDetailScreen({
    super.key,
    required this.project,
    required this.user,
  });

  @override
  State<TVProjectDetailScreen> createState() => _TVProjectDetailScreenState();
}

class _TVProjectDetailScreenState extends State<TVProjectDetailScreen> {
  List<Map<String, dynamic>> _updateNotes = [];
  bool _isLoadingNotes = true;
  StreamSubscription<Map<String, dynamic>>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _loadUpdateNotes();
    _initSync();
  }

  Future<void> _initSync() async {
    try {
      final userId = widget.user['id'];

      // Escuchar eventos de sincronización
      _syncSubscription = SyncService.getNavigationStream(userId).listen((
        event,
      ) {
        _handleSyncEvent(event);
      });

      print('✅ TV Project Detail sync initialized');
    } catch (e) {
      print('❌ Error initializing TV project detail sync: $e');
    }
  }

  void _handleSyncEvent(Map<String, dynamic> event) {
    final eventType = event['eventType'];
    final data = event['data'] ?? {};

    print(
      '📺 TV Project Detail received sync event: $eventType with data: $data',
    );

    switch (eventType) {
      case 'navigate_to_home':
      case 'navigate_back_to_home':
        print('📺 TV Project Detail: Navigating back to dashboard (home)');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => TVDashboardScreen(user: widget.user),
            settings: const RouteSettings(name: '/tv_dashboard'),
          ),
          (route) => false,
        );
        break;

      case 'navigate_to_projects':
        print('📺 TV Project Detail: Navigating back to dashboard (projects)');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => TVDashboardScreen(user: widget.user),
            settings: const RouteSettings(name: '/tv_dashboard'),
          ),
          (route) => false,
        );
        break;

      case 'navigate_to_project_detail':
        final projectId = data['projectId'];
        print(
          '📺 TV Project Detail: Request to navigate to project: $projectId, current: ${widget.project.id}',
        );
        if (projectId != null && projectId != widget.project.id) {
          print(
            '📺 TV Project Detail: Different project requested, going back to dashboard first',
          );
          // Volver al dashboard primero, el dashboard manejará la navegación al nuevo proyecto
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => TVDashboardScreen(user: widget.user),
              settings: const RouteSettings(name: '/tv_dashboard'),
            ),
            (route) => false,
          );
        } else if (projectId == widget.project.id) {
          print('📺 TV Project Detail: Same project requested, staying here');
        }
        break;

      case 'project_updated':
        final updatedProject = data['project'];
        print('📺 TV Project Detail: Project updated event received');
        if (updatedProject != null &&
            updatedProject['id'] == widget.project.id) {
          print(
            '📺 TV Project Detail: Current project was updated, reloading timeline',
          );
          _loadUpdateNotes();
        } else {
          print('📺 TV Project Detail: Different project updated, ignoring');
        }
        break;

      case 'logout':
        print('📺 TV Project Detail: Logout event received');
        _handleLogoutEvent();
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Note: Cannot modify route settings after creation
  }

  void _handleLogoutEvent() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const TVQRScreen()),
      (route) => false,
    );
  }

  Future<void> _loadUpdateNotes() async {
    try {
      print('🔍 TV Project Detail - Loading update notes...');

      // Intentar cargar actividades reales del proyecto
      final activities = await ActivityService.getActivitiesByProject(
        widget.project.id,
      );

      if (mounted) {
        setState(() {
          if (activities.isNotEmpty) {
            // Usar actividades reales como notas de actualización
            // Ordenar por fecha más reciente primero
            activities.sort((a, b) {
              try {
                final dateA = DateTime.parse(
                  a.createdAt?.toIso8601String() ?? '',
                );
                final dateB = DateTime.parse(
                  b.createdAt?.toIso8601String() ?? '',
                );
                return dateB.compareTo(dateA); // Más reciente primero
              } catch (e) {
                return 0;
              }
            });

            _updateNotes = activities.map((activity) {
              return {
                'title': activity.title,
                'description': activity.description ?? 'Sin descripción',
                'date': _formatActivityDate(activity.createdAt),
                'type': activity.type,
                'status': activity.status,
                'indicator': _getIndicatorFromType(activity.type),
                'indicatorValue': _getIndicatorValueFromStatus(activity.status),
              };
            }).toList();
          } else {
            // Si no hay actividades, mostrar lista vacía
            _updateNotes = [];
          }
          _isLoadingNotes = false;
        });

        print(
          '✅ TV Project Detail - Update notes loaded: ${_updateNotes.length} notes',
        );
      }
    } catch (e) {
      print('Error loading update notes: $e');
      if (mounted) {
        setState(() {
          _updateNotes = [];
          _isLoadingNotes = false;
        });
      }
    }
  }

  String _formatActivityDate(DateTime? dateTime) {
    if (dateTime == null) return 'Sin fecha';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
  }

  String _getIndicatorFromType(String type) {
    switch (type) {
      case 'installation':
        return 'Instalaciones';
      case 'review':
        return 'Calidad';
      case 'completion':
        return 'Tiempo';
      case 'inspection':
        return 'Calidad';
      case 'maintenance':
        return 'Presupuesto';
      default:
        return 'Satisfacción';
    }
  }

  double _getIndicatorValueFromStatus(String status) {
    switch (status) {
      case 'completed':
        return 1.0;
      case 'in_progress':
        return 0.6;
      case 'pending':
        return 0.3;
      default:
        return 0.0;
    }
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header exacto al mockup
                _buildMockupHeader(),

                const SizedBox(height: 24),

                // Layout principal según mockup
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Panel izquierdo - Detalles del proyecto (como en mockup)
                      Expanded(flex: 3, child: _buildMockupProjectDetails()),

                      const SizedBox(width: 24),

                      // Panel derecho - Cronograma (como en mockup)
                      Expanded(flex: 2, child: _buildMockupProjectTimeline()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockupHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Logo y título
          Row(
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Avanze',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    TextSpan(
                      text: '360',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Container(
                height: 20,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),

              const SizedBox(width: 16),

              const Text(
                'Detalle del Proyecto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Usuario y botón volver
          Row(
            children: [
              Text(
                widget.user['name'].toString().split(' ')[0],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user['position'] ?? 'Supervisor de obra',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
              const SizedBox(width: 16),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    widget.user['name']
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TVDashboardScreen(user: widget.user),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Volver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockupProjectDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel izquierdo - Información del proyecto
          Expanded(flex: 2, child: _buildProjectInfo()),

          const SizedBox(width: 24),

          // Panel derecho - Indicadores clave
          Expanded(flex: 1, child: _buildKeyIndicatorsPanel()),
        ],
      ),
    );
  }

  Widget _buildProjectInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con ubicación y estado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.project.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.project.startDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.project.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.project.status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(widget.project.status),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Imagen del proyecto
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: _buildImageProvider(widget.project.imageUrl) != null
                  ? DecorationImage(
                      image: _buildImageProvider(widget.project.imageUrl)!,
                      fit: BoxFit.cover,
                    )
                  : null,
              color: _buildImageProvider(widget.project.imageUrl) == null
                  ? Colors.grey[700]
                  : null,
            ),
            child: _buildImageProvider(widget.project.imageUrl) == null
                ? const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.grey,
                      size: 60,
                    ),
                  )
                : null,
          ),
        ),

        const SizedBox(height: 20),

        // Información del proyecto
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del proyecto
            Text(
              widget.project.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Cliente
            Text(
              widget.project.clientName,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Presupuesto
            Text(
              'Presupuesto: ${widget.project.budget}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Progreso
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widget.project.progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getProgressColor(widget.project.progress),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(widget.project.progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyIndicatorsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Indicadores Clave',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 20),

        // Indicadores en grid 2x2
        Expanded(
          child: Column(
            children: [
              // Primera fila
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildKeyIndicatorCard(
                        'Calidad',
                        widget.project.keyIndicators['Calidad'] ?? 0.0,
                        const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKeyIndicatorCard(
                        'Tiempo',
                        widget.project.keyIndicators['Tiempo'] ?? 0.0,
                        const Color(0xFFFF9500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Segunda fila
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildKeyIndicatorCard(
                        'Presupuesto',
                        widget.project.keyIndicators['Presupuesto'] ?? 0.0,
                        const Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKeyIndicatorCard(
                        'Satisfacción',
                        widget.project.keyIndicators['Satisfacción'] ?? 0.0,
                        const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMockupInfoCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMockupIndicatorCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(value * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupProjectTimeline() {
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
          // Header
          const Text(
            'Galería del Proyecto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // Carrusel de imágenes
          Flexible(child: _buildImageCarousel()),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    // Lista de imágenes para el carrusel (incluyendo la imagen del proyecto y algunas adicionales)
    final List<String> carouselImages = [
      widget.project.imageUrl,
      'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/416405/pexels-photo-416405.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/1216589/pexels-photo-1216589.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/1105766/pexels-photo-1105766.jpeg?auto=compress&cs=tinysrgb&w=800',
    ];

    return _ImageCarouselWidget(images: carouselImages);
  }

  Widget _buildKeyIndicatorCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(value * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Barra de progreso
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateNoteItem(Map<String, dynamic> update) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  update['title'] ?? 'Actualización',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                update['date'] ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            update['description'] ?? 'Sin descripción',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMockupTimelineItem(Map<String, dynamic> note, int index) {
    final indicator = note['indicator'] ?? 'General';
    final indicatorValue = note['indicatorValue'] ?? 0.0;
    final isCompleted = note['status'] == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF10B981).withOpacity(0.1)
            : indicatorValue > 0
            ? const Color(0xFF6366F1).withOpacity(0.1)
            : const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withOpacity(0.3)
              : indicatorValue > 0
              ? const Color(0xFF6366F1).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Indicador de estado con color del indicador clave
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : indicatorValue > 0
                  ? _getIndicatorColorByName(indicator)
                  : Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 8)
                : null,
          ),

          const SizedBox(width: 12),

          // Contenido de la nota de actualización
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        note['title'] ?? 'Actualización',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      note['date'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$indicator: ${note['description'] ?? 'Sin descripción'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (indicatorValue > 0 && !isCompleted) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: indicatorValue,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getIndicatorColorByName(indicator),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getIndicatorColorByName(String indicator) {
    switch (indicator) {
      case 'Calidad':
        return const Color(0xFF10B981);
      case 'Tiempo':
        return const Color(0xFFFF9500);
      case 'Presupuesto':
        return const Color(0xFF6366F1);
      case 'Satisfacción':
        return const Color(0xFF8B5CF6);
      case 'Instalaciones':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6366F1);
    }
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

      // Usar imagen por defecto si no se puede determinar el tipo
      return const NetworkImage(
        'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800',
      );
    } catch (e) {
      // Usar imagen por defecto en caso de error
      return const NetworkImage(
        'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800',
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Activo':
        return const Color(0xFF10B981);
      case 'Pausado':
        return const Color(0xFFFF9500);
      case 'Completado':
        return const Color(0xFF3B82F6);
      case 'Cancelado':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.7) {
      return const Color(0xFF10B981);
    } else if (progress >= 0.4) {
      return const Color(0xFF6366F1);
    } else {
      return const Color(0xFFEF4444);
    }
  }
}

// Widget para el carrusel de imágenes
class _ImageCarouselWidget extends StatefulWidget {
  final List<String> images;

  const _ImageCarouselWidget({required this.images});

  @override
  State<_ImageCarouselWidget> createState() => _ImageCarouselWidgetState();
}

class _ImageCarouselWidgetState extends State<_ImageCarouselWidget> {
  int _currentIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.images.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.grey, size: 60),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Imagen actual
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(widget.images[_currentIndex]),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Overlay con información
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Imagen ${_currentIndex + 1} de ${widget.images.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  // Indicadores de puntos
                  Row(
                    children: widget.images.asMap().entries.map((entry) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == entry.key
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Indicador de transición
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.slideshow, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  const Text(
                    'Auto',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
