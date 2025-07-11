import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class KeyIndicatorsWidget extends StatelessWidget {
  final Map<String, double> indicators;
  final Function(Map<String, double>) onIndicatorsChanged;

  const KeyIndicatorsWidget({
    super.key,
    required this.indicators,
    required this.onIndicatorsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Indicadores Clave',
            style: AppTextStyles.fieldLabel.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ...indicators.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                      ),
                      Text(
                        '${(entry.value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getIndicatorColor(entry.value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _getIndicatorColor(entry.value),
                      inactiveTrackColor: Colors.grey.withOpacity(0.3),
                      thumbColor: _getIndicatorColor(entry.value),
                      overlayColor: _getIndicatorColor(entry.value).withOpacity(0.2),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: entry.value,
                      onChanged: (value) {
                        final updatedIndicators = Map<String, double>.from(indicators);
                        updatedIndicators[entry.key] = value;
                        onIndicatorsChanged(updatedIndicators);
                      },
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getIndicatorColor(double value) {
    if (value >= 0.8) {
      return const Color(0xFF10B981); // Green
    } else if (value >= 0.6) {
      return const Color(0xFF3B82F6); // Blue
    } else if (value >= 0.4) {
      return const Color(0xFFFF9500); // Orange
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }
}