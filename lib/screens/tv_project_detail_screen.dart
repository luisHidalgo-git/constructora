import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/project_model.dart';
import '../services/activity_service.dart';
import '../models/activity_model.dart';
import 'tv_dashboard_screen.dart';
import '../services/sync_service.dart';
import 'dart:async';
import 'tv_qr_screen.dart';

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
  List<Map<String, dynamic>> _projectTimeline = [];
  bool _isLoadingActivities = true;
  StreamSubscription<Map<String, dynamic>>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _loadProjectTimeline();
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
          _loadProjectTimeline();
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

  Future<void> _loadProjectTimeline() async {
    try {
      // Intentar cargar actividades reales del proyecto
      final activities = await ActivityService.getActivitiesByProject(
        widget.project.id,
      );

      if (activities.isNotEmpty) {
        // Usar actividades reales del servidor
        _projectTimeline = activities.map((activity) {
          return {
            'title': activity.title,
            'date': activity.date,
            'isCompleted': activity.status == 'completed',
            'progress': activity.status == 'completed'
                ? 1.0
                : activity.status == 'in_progress'
                ? 0.5
                : 0.0,
            'type': activity.type,
            'description': activity.description ?? '',
          };
        }).toList();
      } else {
        // Si no hay actividades reales, generar timeline basado en el progreso del proyecto
        _generateTimelineFromProgress();
      }

      setState(() {
        _isLoadingActivities = false;
      });
    } catch (e) {
      print('Error loading project activities: $e');
      // En caso de error, generar timeline basado en progreso
      _generateTimelineFromProgress();
      setState(() {
        _isLoadingActivities = false;
      });
    }
  }

  void _generateTimelineFromProgress() {
    _projectTimeline.clear();

    // Generar timeline basado en el progreso real del proyecto
    final totalPhases = 8;
    final completedPhases = (totalPhases * widget.project.progress).round();

    final phaseNames = [
      'Planificación inicial',
      'Preparación del terreno',
      'Cimentación',
      'Estructura principal',
      'Instalaciones eléctricas',
      'Instalaciones sanitarias',
      'Acabados interiores',
      'Finalización y entrega',
    ];

    final startDate = DateTime.now().subtract(const Duration(days: 60));

    for (int i = 0; i < totalPhases; i++) {
      final isCompleted = i < completedPhases;
      final phaseDate = startDate.add(Duration(days: i * 7));

      _projectTimeline.add({
        'title': phaseNames[i],
        'date':
            '${phaseDate.day.toString().padLeft(2, '0')}/${phaseDate.month.toString().padLeft(2, '0')}/${phaseDate.year}',
        'isCompleted': isCompleted,
        'progress': isCompleted
            ? 1.0
            : (i == completedPhases
                  ? (widget.project.progress * totalPhases) - completedPhases
                  : 0.0),
        'type': 'construction',
        'description': 'Fase de construcción',
      });
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
                      Expanded(flex: 2, child: _buildMockupProjectDetails()),

                      const SizedBox(width: 24),

                      // Panel derecho - Cronograma (como en mockup)
                      Expanded(flex: 1, child: _buildMockupProjectTimeline()),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del proyecto con icono y estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.construction,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.project.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.project.status),
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
            ],
          ),

          const SizedBox(height: 24),

          // Grid de información como en mockup
          Row(
            children: [
              Expanded(
                child: _buildMockupInfoCard(
                  'Cliente',
                  widget.project.clientName,
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMockupInfoCard(
                  'Presupuesto',
                  widget.project.budget,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMockupInfoCard(
                  'Inicio',
                  widget.project.startDate,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMockupInfoCard(
                  'Fin Estimado',
                  widget.project.endDate,
                  const Color(0xFFFF9500),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progreso General como en mockup
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progreso General',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${(widget.project.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _getProgressColor(widget.project.progress),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
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
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Indicadores Clave como en mockup
          const Text(
            'Indicadores Clave',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildMockupIndicatorCard(
                    'Calidad',
                    widget.project.keyIndicators['Calidad'] ?? 0.0,
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMockupIndicatorCard(
                    'Tiempo',
                    widget.project.keyIndicators['Tiempo'] ?? 0.0,
                    const Color(0xFFFF9500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            'Cronograma del Proyecto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // Timeline con datos reales
          Expanded(
            child: _isLoadingActivities
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  )
                : ListView.builder(
                    itemCount: _projectTimeline.length,
                    itemBuilder: (context, index) {
                      final activity = _projectTimeline[index];
                      return _buildMockupTimelineItem(activity, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupTimelineItem(Map<String, dynamic> activity, int index) {
    final isCompleted = activity['isCompleted'];
    final progress = activity['progress'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF10B981).withOpacity(0.1)
            : progress > 0
            ? const Color(0xFF6366F1).withOpacity(0.1)
            : const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withOpacity(0.3)
              : progress > 0
              ? const Color(0xFF6366F1).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Indicador de estado
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : progress > 0
                  ? const Color(0xFF6366F1)
                  : Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 8)
                : null,
          ),

          const SizedBox(width: 12),

          // Contenido de la actividad
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity['title'],
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
                      activity['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                if (progress > 0 && !isCompleted) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
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
