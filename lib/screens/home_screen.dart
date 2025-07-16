import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart';
import '../widgets/project_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/project_service.dart';
import '../services/stats_service.dart';
import '../services/auth_service.dart';
import '../models/project_model.dart';
import '../models/stats_model.dart';
import '../models/user_model.dart';
import 'home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProjectModel> _projects = [];
  StatsModel? _stats;
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Cargar solo el usuario, los proyectos y stats se cargan cuando existan
      final user = await AuthService.getSavedUser();

      setState(() {
        _projects = []; // Iniciar vacío
        _stats = null; // Iniciar vacío
        _currentUser =
            user ??
            UserModel(
              id: 'demo',
              name: 'Usuario Demo',
              email: 'demo@example.com',
              role: 'supervisor',
              position: 'Supervisor',
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
        _isLoading = false;
      });

      // Intentar cargar datos reales en segundo plano
      _loadRealData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRealData() async {
    try {
      final results = await Future.wait([
        ProjectService.getProjects(),
        StatsService.getStats(),
      ]);

      setState(() {
        _projects = results[0] as List<ProjectModel>;
        _stats = results[1] as StatsModel;
      });
    } catch (e) {
      // Si no hay datos reales, mantener vacío
      print('No hay datos reales disponibles: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadRealData();
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${_currentUser?.name ?? 'Usuario'}!',
                        style: AppTextStyles.header.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUser?.position ?? 'Supervisor',
                        style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
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
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QRScannerScreen(),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.iconGray,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
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
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar un proyecto...',
                    hintStyle: AppTextStyles.hintText.copyWith(fontSize: 14),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.iconGray,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Stats Cards
            _buildStatsSection(),

            const SizedBox(height: 20),

            // Projects Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Section Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Proyectos Recientes',
                            style: AppTextStyles.header.copyWith(fontSize: 18),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Ver todos',
                              style: AppTextStyles.linkText.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 0),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_stats == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 120,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            SizedBox(
              width: 180,
              child: StatsCard(
                title: '${_stats!.activeProjects}',
                subtitle: 'Proyectos Activos',
                color: AppColors.primary,
                icon: Icons.refresh,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: StatsCard(
                title: '${_stats!.activeAlerts}',
                subtitle: 'Alertas Activas',
                color: const Color(0xFFFF9500),
                icon: Icons.notifications,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: StatsCard(
                title: _stats!.totalBudget,
                subtitle: 'Presupuesto Total',
                color: const Color(0xFF10B981),
                icon: Icons.attach_money,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: StatsCard(
                title: '${(_stats!.averageProgress * 100).toInt()}%',
                subtitle: 'Progreso Medio',
                color: const Color(0xFF8B5CF6),
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
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
              onPressed: _refreshData,
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
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        children: [
          ..._projects
              .map(
                (project) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ProjectCard(
                    project: project,
                    title: project.name,
                    subtitle: project.description,
                    progress: project.progress,
                    status: project.status,
                    imageUrl: project.imageUrl,
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
