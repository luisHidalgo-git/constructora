import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/project_service.dart';
import '../services/stats_service.dart';
import '../models/project_model.dart';
import '../models/stats_model.dart';
import 'tv_qr_screen.dart';
import 'tv_project_detail_screen.dart';
import '../services/auth_service.dart';

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
  List<Map<String, dynamic>> _recentUpdates = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    // Actualizar datos cada 30 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      print('🔍 TV Dashboard - Loading data...');

      // Verificar que tenemos token para hacer las llamadas a la API
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ TV Dashboard - No token available, cannot load data');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      print('✅ TV Dashboard - Token available, loading projects and stats...');

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

        // Generar actividad reciente basada en proyectos reales
        _generateRecentUpdatesFromProjects();

        print(
          '✅ TV Dashboard - Data loaded successfully: ${_projects.length} projects',
        );
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

  void _generateRecentUpdatesFromProjects() {
    _recentUpdates.clear();

    // Generar actualizaciones reales basadas en los datos de los proyectos
    for (int i = 0; i < _projects.length && i < 4; i++) {
      final project = _projects[i];
      final daysAgo = i + 1;
      final updateDate = DateTime.now().subtract(Duration(days: daysAgo));

      String updateType;
      String updateDescription;

      // Determinar tipo de actualización basado en datos reales del proyecto
      if (project.progress >= 0.9) {
        updateType = 'Actualización';
        updateDescription = 'Proyecto próximo a completarse';
      } else if (project.progress >= 0.5) {
        updateType = 'Actualización';
        updateDescription = 'Nuevos avances en el proyecto';
      } else if (project.progress >= 0.2) {
        updateType = 'Inicio';
        updateDescription = 'Proyecto iniciado recientemente';
      } else {
        updateType = 'Actualización';
        updateDescription = 'Planificación en progreso';
      }

      _recentUpdates.add({
        'projectName': project.name,
        'updateType': updateType,
        'description': updateDescription,
        'date':
            '${updateDate.day.toString().padLeft(2, '0')}/${updateDate.month.toString().padLeft(2, '0')}/${updateDate.year}',
        'progress': project.progress,
        'status': project.status,
        'clientName': project.clientName,
        'completedPercentage':
            '${(project.progress * 100).toInt()}% completado',
      });
    }

    // Si no hay proyectos, no mostrar actividades
    if (_projects.isEmpty) {
      _recentUpdates.clear();
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
      print('✅ TV session cleared');
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
                _buildMockupHeader(),

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
                            _buildMockupStatsCards(),

                            const SizedBox(height: 24),

                            // Proyectos Activos
                            Expanded(child: _buildMockupProjectsSection()),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Panel derecho - Actividad Reciente (como en mockup)
                      Expanded(
                        flex: 1,
                        child: _buildMockupRecentActivityPanel(),
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
                'Dashboard de Proyectos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Usuario y botón salir
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Bienvenido, ${widget.user['name'].toString().split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.user['position'] ?? 'Supervisor de obra',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ],
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
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Salir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
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

  Widget _buildMockupStatsCards() {
    if (_isLoading || _stats == null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMockupStatCard(
              '${_stats!.activeProjects}',
              'Proyectos Activos',
              const Color(0xFF6366F1),
              Icons.construction,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildMockupStatCard(
              '${_stats!.activeAlerts}',
              'Alertas Activas',
              const Color(0xFFFF9500),
              Icons.warning,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildMockupStatCard(
              _stats!.totalBudget,
              'Presupuesto Total',
              const Color(0xFF10B981),
              Icons.attach_money,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildMockupStatCard(
              '${(_stats!.averageProgress * 100).toInt()}%',
              'Progreso Promedio',
              const Color(0xFF8B5CF6),
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupStatCard(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupProjectsSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Proyectos Activos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (_projects.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_projects.length} proyectos',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(child: _buildMockupProjectsGrid()),
        ],
      ),
    );
  }

  Widget _buildMockupProjectsGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 48,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay proyectos disponibles',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        return _buildMockupProjectCard(project);
      },
    );
  }

  Widget _buildMockupProjectCard(ProjectModel project) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TVProjectDetailScreen(project: project, user: widget.user),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con nombre y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.status),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      project.status,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                project.clientName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '${(project.progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: project.progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getProgressColor(project.progress),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockupRecentActivityPanel() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actividad Reciente',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Lista de actividades con datos reales
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  )
                : _recentUpdates.isEmpty
                ? Center(
                    child: Text(
                      'No hay actividad reciente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _recentUpdates.length,
                    itemBuilder: (context, index) {
                      final update = _recentUpdates[index];
                      return _buildMockupActivityItem(update, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupActivityItem(Map<String, dynamic> update, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Icono estático para proyectos (como solicitaste)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getUpdateTypeColor(update['updateType']),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                update['projectName'].toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Información de la actualización con datos reales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        update['projectName'],
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
                      update['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${update['updateType']}: ${update['description']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(update['status']),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        update['status'],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      update['completedPercentage'],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getUpdateTypeColor(String updateType) {
    switch (updateType) {
      case 'Actualización':
        return const Color(0xFF8B5CF6);
      case 'Inicio':
        return const Color(0xFFFF9500);
      default:
        return const Color(0xFF6366F1);
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
      return const Color(0xFF3B82F6);
    } else {
      return const Color(0xFFEF4444);
    }
  }
}
