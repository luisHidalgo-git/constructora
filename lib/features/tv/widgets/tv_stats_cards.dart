import 'package:flutter/material.dart';
import '../../../models/stats_model.dart';

class TVStatsCards extends StatelessWidget {
  final StatsModel? stats;
  final bool isLoading;

  const TVStatsCards({
    super.key,
    required this.stats,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || stats == null) {
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
            child: _buildStatCard(
              '${stats!.activeProjects}',
              'Proyectos Activos',
              const Color(0xFF6366F1),
              Icons.construction,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              '${stats!.activeAlerts}',
              'Alertas Activas',
              const Color(0xFFFF9500),
              Icons.warning,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              stats!.totalBudget,
              'Presupuesto Total',
              const Color(0xFF10B981),
              Icons.attach_money,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              '${(stats!.averageProgress * 100).toInt()}%',
              'Progreso Promedio',
              const Color(0xFF8B5CF6),
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
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
}