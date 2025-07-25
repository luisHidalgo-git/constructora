import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/app_colors.dart';
import '../services/project_service.dart';
import '../services/stats_service.dart';
import '../models/project_model.dart';
import '../models/stats_model.dart';
import 'tv_qr_screen.dart';
import 'tv_project_detail_screen.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../features/tv/widgets/tv_header.dart';
import '../features/tv/widgets/tv_stats_cards.dart';
import '../features/tv/widgets/tv_projects_grid.dart';
import '../features/tv/widgets/tv_activity_panel.dart';
import '../features/tv/utils/tv_data_generator.dart';

class TVDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const TVDashboardScreen({super.key, required this.user});

  @override
  State<TVDashboardScreen> createState() => _TVDashboardScreenState();
}

class _TVDashboardScreenState extends State<TVDashboardScreen> {
  List<ProjectModel> _projects = [];
  StatsModel? _stats;
  bool _isLoading = true;
  Timer? _refreshTimer;
  StreamSubscription<Map<String, dynamic>>? _syncSubscription;
  List<Map<String, dynamic>> _recentUpdates = [];
  String? _lastProcessedEventId; // Para evitar procesar eventos duplicados

  @override
  void initState() {
    super.initState();
    _loadData();
    _initSync();
    // Actualizar datos cada 30 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }

  Future<void> _initSync() async {
    try {
      final userId = widget.user['id'];
      print('🔄 TV Dashboard: Initializing sync for user: $userId');
      await SyncService.startSync(userId);

      // Escuchar eventos de sincronización
      _syncSubscription?.cancel(); // Cancelar suscripción anterior si existe
      _syncSubscription = SyncService.getNavigationStream(userId).listen((
        event,
      ) {
        _handleSyncEvent(event);
      }, onError: (error) {
        print('❌ TV Dashboard: Sync stream error: $error');
        // Intentar reconectar después de un error
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _initSync();
          }
        });
      });

      print('✅ TV Dashboard: Sync initialized successfully');
    } catch (e) {
      print('❌ Error initializing TV sync: $e');
      // Reintentar inicialización después de un error
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _initSync();
        }
      });
    }
  }

  void _handleSyncEvent(Map<String, dynamic> event) {
    final eventType = event['eventType'];
    final data = event['data'] ?? {};
    final eventId = event['eventId']?.toString();
    final processedAt = event['processedAt'];

    print('📺 TV Dashboard: Received sync event: $eventType (ID: $eventId, processed: $processedAt)');

    // Evitar procesar el mismo evento múltiples veces
    if (eventId != null && eventId == _lastProcessedEventId) {
      print('⚠️ TV Dashboard: Skipping duplicate event: $eventType (ID: $eventId)');
      return;
    }
    _lastProcessedEventId = eventId;

    switch (eventType) {
      case 'navigate_to_home':
      case 'navigate_back_to_home':
        print('📺 TV Dashboard: Staying on dashboard (already on home)');
        break;

      case 'navigate_to_projects':
        print('📺 TV Dashboard: Staying on dashboard (projects view)');
        break;

      case 'navigate_to_project_detail':
        final projectId = data['projectId'];
        if (projectId != null) {
          print('📺 TV Dashboard: Navigating to project detail: $projectId');
          _navigateToProjectDetail(projectId);
        } else {
          print('❌ TV Dashboard: No projectId provided for navigate_to_project_detail');
        }
        break;

      case 'project_updated':
      case 'project_created':
        print('📺 TV Dashboard: Refreshing data due to project changes');
        _loadData();
        break;

      case 'logout':
        print('📺 TV Dashboard: Handling logout event');
        _handleLogoutEvent();
        break;

      default:
        print('⚠️ TV Dashboard: Unknown event type: $eventType');
    }
  }

  void _navigateToProjectDetail(String projectId) {
    print('🔍 TV Dashboard: Looking for project with ID: $projectId');
    
    ProjectModel? project;
    try {
      project = _projects.firstWhere((p) => p.id == projectId);
      print('✅ TV Dashboard: Found project: ${project.name}');
      _performNavigation(project);
    } catch (e) {
      print('⚠️ TV Dashboard: Project not found in current list, refreshing data...');
      _loadData().then((_) {
        try {
          project = _projects.firstWhere((p) => p.id == projectId);
          print('✅ TV Dashboard: Found project after refresh: ${project!.name}');
          _performNavigation(project!);
        } catch (e) {
          print('❌ TV Dashboard: Project still not found after refresh: $projectId');
          if (_projects.isNotEmpty) {
            print('🔄 TV Dashboard: Using first available project as fallback');
            _performNavigation(_projects.first);
          } else {
            print('❌ TV Dashboard: No projects available for navigation');
          }
        }
      });
    }
  }

  void _performNavigation(ProjectModel project) {
    print('🚀 TV Dashboard: Performing navigation to project: ${project.name} (${project.id})');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TVProjectDetailScreen(project: project, user: widget.user),
        settings: const RouteSettings(name: '/tv_project_detail'),
      ),
    ).then((_) {
      print('🔄 TV Dashboard: Returned from project detail, reinitializing sync...');
      // Reinicializar sync al regresar
      _initSync();
    );
  }

  void _handleLogoutEvent() {
    print('🚪 TV Dashboard: Processing logout event');
    _clearTVSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TVQRScreen()),
    );
  }

  @override
  void dispose() {
    print('🔄 TV Dashboard: Disposing...');
    _refreshTimer?.cancel();
    _syncSubscription?.cancel();
    // No detener sync completamente, solo la suscripción
    print('✅ TV Dashboard: Disposed');
    super.dispose();
  }

  Future<void> _loadData() async {
    try {

      final token = await AuthService.getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }


      final results = await Future.wait([
        ProjectService.getProjects(),
        StatsService.getStats(),
      ]);

      if (mounted) {
        setState(() {
          _projects = results[0] as List<ProjectModel>;
          _stats = results[1] as StatsModel;
          _isLoading = false;
        });

        _recentUpdates = TVDataGenerator.generateRecentUpdatesFromProjects(_projects);
      }
    } catch (e) {
      print('Error loading TV dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar la sesión en TV?',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearTVSession();
                SyncService.stopSync();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const TVQRScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Salir',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  // Limpiar sesión de TV
  Future<void> _clearTVSession() async {
    try {
      await AuthService.logout();
    } catch (e) {
      print('❌ Error clearing TV session: $e');
    }
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
                TVHeader(
                  title: 'Dashboard de Proyectos',
                  user: widget.user,
                  onLogout: _logout,
                ),

                const SizedBox(height: 24),

                // Layout principal según mockup
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Panel izquierdo - Stats y Proyectos (como en mockup)
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            // Stats Cards en fila horizontal
                            TVStatsCards(
                              stats: _stats,
                              isLoading: _isLoading,
                            ),

                            const SizedBox(height: 24),

                            // Proyectos Activos
                            Expanded(
                              child: TVProjectsGrid(
                                projects: _projects,
                                isLoading: _isLoading,
                                onProjectTap: (project) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TVProjectDetailScreen(
                                        project: project,
                                        user: widget.user,
                                      ),
                                      settings: const RouteSettings(name: '/tv_project_detail'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Panel derecho - Actividad Reciente (como en mockup)
                      Expanded(
                        flex: 1,
                        child: TVActivityPanel(
                          recentUpdates: _recentUpdates,
                          isLoading: _isLoading,
                        ),
                      ),
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
}
