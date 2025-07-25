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
import 'update_project_screen.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/error_widget.dart';
import '../core/widgets/empty_state_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ProjectModel> _projects = [];
  List<ProjectModel> _filteredProjects = [];
  StatsModel? _stats;
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'Todos';
  bool _showProjects = true;

  final List<String> _filterOptions = [
    'Todos',
    'Activo',
    'Pausado',
    'Completado',
    'Cancelado',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
    _initSync();
  }

  Future<void> _initSync() async {
    try {
      final user = await AuthService.getSavedUser();
      if (user != null) {
        await SyncService.startSync(user.id);
        // Solo enviar evento si no estamos ya en home
        if (SyncService.currentScreen != 'home') {
          await SyncService.navigateToHome();
          print('📱 Mobile: Sent navigate_to_home event from HomeScreen');
        }
      }
    } catch (e) {
      print('Error initializing sync in home: $e');
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterProjects();
  }

  void _filterProjects() {
    setState(() {
      _filteredProjects = _projects.where((project) {
        final matchesSearch =
            _searchController.text.isEmpty ||
            project.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            project.clientName.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            project.location.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );

        final matchesFilter =
            _selectedFilter == 'Todos' || project.status == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
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
        _filteredProjects = [];
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
        _filteredProjects = _projects;
        _stats = results[1] as StatsModel;
      });
      _filterProjects();
    } catch (e) {
      // Si no hay datos reales, mantener vacío
      print('No hay datos reales disponibles: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadRealData();
  }

  void _navigateToCreateProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UpdateProjectScreen()),
    );

    // Si se creó un proyecto, actualizar la lista
    if (result != null) {
      _refreshData();
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
                  // Eliminar el botón QR de la parte superior derecha
                  // (remover este bloque)
                  // Container(
                  //   width: 40,
                  //   height: 40,
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(12),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: Colors.black.withOpacity(0.05),
                  //         blurRadius: 10,
                  //         offset: const Offset(0, 2),
                  //       ),
                  //     ],
                  //   ),
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => const QRScannerScreen(),
                  //         ),
                  //       );
                  //     },
                  //     child: const Icon(
                  //       Icons.qr_code_scanner,
                  //       color: AppColors.iconGray,
                  //       size: 20,
                  //     ),
                  //   ),
                  // ),
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
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar un proyecto...',
                    hintStyle: AppTextStyles.hintText.copyWith(fontSize: 14),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.iconGray,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.iconGray,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
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

            // Filter Chips
            Container(
              height: 50,
              margin: const EdgeInsets.only(top: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filterOptions.length,
                itemBuilder: (context, index) {
                  final filter = _filterOptions[index];
                  final isSelected = _selectedFilter == filter;

                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textGray,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        _filterProjects();
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.withOpacity(0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
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
                            _searchController.text.isNotEmpty ||
                                    _selectedFilter != 'Todos'
                                ? 'Resultados (${_filteredProjects.length})'
                                : 'Proyectos Recientes',
                            style: AppTextStyles.header.copyWith(fontSize: 18),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showProjects = !_showProjects;
                              });
                            },
                            child: Text(
                              _showProjects ? 'Ocultar todos' : 'Ver todos',
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
                    Expanded(child: _showProjects ? _buildProjectsList() : Container()),
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
      return const LoadingWidget();
    }

    if (_error != null) {
      return CustomErrorWidget(
        title: 'Error al cargar proyectos',
        message: _error!,
        onRetry: _refreshData,
      );
    }

    if (_filteredProjects.isEmpty && _projects.isNotEmpty) {
      return const EmptyStateWidget(
        title: 'No se encontraron proyectos',
        message: 'Intenta con otros términos de búsqueda',
        icon: Icons.search_off,
      );
    }

    if (_projects.isEmpty) {
      return const EmptyStateWidget(
        title: 'No hay proyectos',
        message: 'Crea tu primer proyecto para comenzar',
        icon: Icons.construction,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        children: [
          ..._filteredProjects
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
                    onTap: null, // Deshabilitar navegación
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}