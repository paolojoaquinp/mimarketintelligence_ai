import 'package:flutter/material.dart';
import '../domain/price_simulation_result.dart';

/// A visual traffic light indicator for the profitability margin (US03 AC3).
class MarginTrafficLightWidget extends StatelessWidget {
  final MarginTrafficLight trafficLight;
  final double marginPercentage;

  const MarginTrafficLightWidget({
    super.key,
    required this.trafficLight,
    required this.marginPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (trafficLight) {
      MarginTrafficLight.green => (
          Colors.green,
          'Margen Óptimo (>30%)',
          Icons.sentiment_very_satisfied,
        ),
      MarginTrafficLight.yellow => (
          Colors.orange,
          'Margen Riesgoso (15-30%)',
          Icons.sentiment_neutral,
        ),
      MarginTrafficLight.red => (
          Colors.red,
          'Margen Crítico (<15%)',
          Icons.sentiment_very_dissatisfied,
        ),
    };

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Margen Calculado: \$${marginPercentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
