import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../widgets/project_detail_card.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/project_service.dart';
import '../models/project_model.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<ProjectModel> _projects = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final projects = await ProjectService.getProjects();
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _projects = []; // Mantener vacío si no hay datos
        _isLoading = false;
        // No mostrar error si simplemente no hay datos
      });
    }
  }

  Future<void> _refreshProjects() async {
    await _loadProjects();
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
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    },
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
                      'Mis Proyectos',
                      style: AppTextStyles.header.copyWith(fontSize: 20),
                    ),
                  ),
                  GestureDetector(
                    onTap: _refreshProjects,
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
                        Icons.refresh,
                        color: AppColors.iconGray,
                        size: 20,
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
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 1),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
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
              onPressed: _refreshProjects,
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
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey[400],
            ),
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
      onRefresh: _refreshProjects,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        children: [
          ..._projects.map((project) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ProjectDetailCard(
              project: project,
              title: project.name,
              location: project.location,
              date: project.startDate,
              progress: project.progress,
              status: project.status,
              budget: project.budget,
              imageUrl: project.imageUrl,
            ),
          )).toList(),
        ],
      ),
    );
  }
}