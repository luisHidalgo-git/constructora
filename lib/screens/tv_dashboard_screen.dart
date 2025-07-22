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

  const TVDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<TVDashboardScreen> createState() => _TVDashboardScreenState();
}

class _TVDashboardScreenState extends State<TVDashboardScreen> {
  List<ProjectModel> _projects = [];
  StatsModel? _stats;
  bool _isLoading = true;
  Timer? _refreshTimer;

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
        print('✅ TV Dashboard - Data loaded successfully: ${_projects.length} projects');
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
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
                  MaterialPageRoute(
                    builder: (context) => const TVQRScreen(),
                  ),
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
                'Cerrar Sesión',
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
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF2D2D2D),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: 30),
                
                // Stats Cards
                _buildStatsCards(),
                
                const SizedBox(height: 30),
                
                // Projects Grid
                Expanded(
                  child: _buildProjectsGrid(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Logo
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Avanze',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
              TextSpan(
                text: '360',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 20),
        
        const Text(
          'Monitor de Proyectos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        
        const Spacer(),
        
        // User Info
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  widget.user['name']
                      .toString()
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${widget.user['name'].toString().split(' ')[0]}!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.user['position'] ?? 'Supervisor',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    if (_isLoading || _stats == null) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '${_stats!.activeProjects}',
            'Proyectos Activos',
            const Color(0xFF007AFF),
            Icons.refresh,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            '${_stats!.activeAlerts}',
            'Alertas Activas',
            const Color(0xFFFF9500),
            Icons.notifications,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            _stats!.totalBudget,
            'Presupuesto Total',
            const Color(0xFF10B981),
            Icons.attach_money,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            '${(_stats!.averageProgress * 100).toInt()}%',
            'Progreso Medio',
            const Color(0xFF8B5CF6),
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay proyectos disponibles',
              style: TextStyle(
                fontSize: 18,
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
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.8,
      ),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TVProjectDetailScreen(
              project: project,
              user: widget.user,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Image and Status
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(project.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      ],
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
              
              const SizedBox(height: 16),
              
              // Progress Bar
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
              
              const Spacer(),
              
              // Days remaining
              Text(
                '${_calculateDaysRemaining(project.endDate)} días restantes',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
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
      return const Color(0xFF3B82F6);
    } else {
      return const Color(0xFFEF4444);
    }
  }

  int _calculateDaysRemaining(String endDate) {
    try {
      final parts = endDate.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final end = DateTime(year, month, day);
        final now = DateTime.now();
        return end.difference(now).inDays;
      }
    } catch (e) {
      print('Error calculating days remaining: $e');
    }
    return 0;
  }
}