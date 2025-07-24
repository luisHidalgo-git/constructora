import 'package:flutter/material.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/widgets/loading_widget.dart';

class TVActivityPanel extends StatelessWidget {
  final List<Map<String, dynamic>> recentUpdates;
  final bool isLoading;

  const TVActivityPanel({
    super.key,
    required this.recentUpdates,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
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
            'Actividad Reciente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(child: _buildActivityContent()),
        ],
      ),
    );
  }

  Widget _buildActivityContent() {
    if (isLoading) {
      return const LoadingWidget(color: Color(0xFF6366F1));
    }

    if (recentUpdates.isEmpty) {
      return Center(
        child: Text(
          'No hay actividad reciente',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: recentUpdates.length,
      itemBuilder: (context, index) {
        final update = recentUpdates[index];
        return _buildActivityItem(update);
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> update) {
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ColorUtils.getUpdateTypeColor(update['updateType']),
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
                        color: ColorUtils.getStatusColor(update['status']),
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
}