import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/project_model.dart';
import '../services/activity_service.dart';
import '../models/activity_model.dart';
import 'tv_dashboard_screen.dart';
import '../services/sync_service.dart';
import 'dart:async';
import 'tv_qr_screen.dart';
import '../features/tv/widgets/tv_header.dart';
import '../core/utils/image_utils.dart';
import '../core/utils/color_utils.dart';
import '../core/utils/formatters.dart';

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
        _navigateBackToDashboard();
        break;

      case 'navigate_to_projects':
        _navigateBackToDashboard();
        break;

      case 'navigate_to_project_detail':
        final projectId = data['projectId'];
        if (projectId != null && projectId != widget.project.id) {
          _navigateBackToDashboard();
        }
        break;

      case 'project_updated':
        final updatedProject = data['project'];
        if (updatedProject != null &&
            updatedProject['id'] == widget.project.id) {
          _loadUpdateNotes();
        }
        break;

      case 'logout':
        _handleLogoutEvent();
        break;
    }
  }

  void _navigateBackToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => TVDashboardScreen(user: widget.user),
        settings: const RouteSettings(name: '/tv_dashboard'),
      ),
      (route) => false,
    );
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

      final activities = await ActivityService.getActivitiesByProject(
        widget.project.id,
      );

      if (mounted) {
        setState(() {
          if (activities.isNotEmpty) {
            activities.sort((a, b) {
              try {
                final dateA = DateTime.parse(
                  a.createdAt?.toIso8601String() ?? '',
                );
                final dateB = DateTime.parse(
                  b.createdAt?.toIso8601String() ?? '',
                );
                return dateB.compareTo(dateA);
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
    return Formatters.formatActivityDate(dateTime);
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

  Color _getIndicatorColorByName(String indicator) {
    return ColorUtils.getIndicatorColorByName(indicator);
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
                TVHeader(
                  title: 'Detalle del Proyecto',
                  user: widget.user,
                  onBack: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TVDashboardScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildProjectDetails()),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildProjectTimeline()),
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

  Widget _buildProjectDetails() {
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
          Expanded(flex: 2, child: _buildProjectInfo()),
          const SizedBox(width: 24),
          Expanded(flex: 1, child: _buildKeyIndicatorsPanel()),
        ],
      ),
    );
  }

  Widget _buildProjectInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProjectHeader(),
        const SizedBox(height: 20),
        Expanded(child: _buildProjectImage()),
        const SizedBox(height: 20),
        _buildProjectBasicInfo(),
      ],
    );
  }

  Widget _buildProjectHeader() {
    return Row(
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
            color: ColorUtils.getStatusColor(
              widget.project.status,
            ).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.project.status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ColorUtils.getStatusColor(widget.project.status),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectImage() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: ImageUtils.buildImageProvider(widget.project.imageUrl) != null
            ? DecorationImage(
                image: ImageUtils.buildImageProvider(widget.project.imageUrl)!,
                fit: BoxFit.cover,
              )
            : null,
        color: ImageUtils.buildImageProvider(widget.project.imageUrl) == null
            ? Colors.grey[700]
            : null,
      ),
      child: ImageUtils.buildImageProvider(widget.project.imageUrl) == null
          ? const Center(
              child: Icon(Icons.image_outlined, color: Colors.grey, size: 60),
            )
          : null,
    );
  }

  Widget _buildProjectBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Text(
          widget.project.clientName,
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
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
        _buildProgressBar(),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Row(
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
                  color: ColorUtils.getProgressColor(widget.project.progress),
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
        Expanded(
          child: Column(
            children: [
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

  Widget _buildProjectTimeline() {
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
          const Text(
            'Galería del Proyecto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Flexible(child: _buildImageCarousel()),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    final List<String> carouselImages = [
      widget.project.imageUrl,
      'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/416405/pexels-photo-416405.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/1216589/pexels-photo-1216589.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/1105766/pexels-photo-1105766.jpeg?auto=compress&cs=tinysrgb&w=800',
    ];

    return _ImageCarouselWidget(images: carouselImages);
  }
}

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
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.slideshow, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
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
