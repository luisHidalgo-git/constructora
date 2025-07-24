import 'package:flutter/material.dart';
import '../../../widgets/progress_indicator_widget.dart';
import '../../../widgets/status_selector.dart';
import '../../../widgets/key_indicators_widget.dart';
import '../../../widgets/update_notes_widget.dart';

class ProjectUpdateFields extends StatelessWidget {
  final double progress;
  final String status;
  final Map<String, double> keyIndicators;
  final TextEditingController notesController;
  final Function(double) onProgressChanged;
  final Function(String) onStatusChanged;
  final Function(Map<String, double>) onIndicatorsChanged;

  const ProjectUpdateFields({
    super.key,
    required this.progress,
    required this.status,
    required this.keyIndicators,
    required this.notesController,
    required this.onProgressChanged,
    required this.onStatusChanged,
    required this.onIndicatorsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Project Progress
        ProgressIndicatorWidget(
          progress: progress,
          onProgressChanged: onProgressChanged,
        ),

        const SizedBox(height: 24),

        // Project Status
        StatusSelector(
          currentStatus: status,
          onStatusChanged: onStatusChanged,
        ),

        const SizedBox(height: 24),

        // Key Indicators
        KeyIndicatorsWidget(
          indicators: keyIndicators,
          onIndicatorsChanged: onIndicatorsChanged,
        ),

        const SizedBox(height: 24),

        // Update Notes
        UpdateNotesWidget(controller: notesController),
      ],
    );
  }
}