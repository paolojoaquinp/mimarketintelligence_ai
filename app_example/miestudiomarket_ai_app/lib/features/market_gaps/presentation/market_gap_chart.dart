// Market Gap scatter chart visualization (US02 AC2).
//
// X-axis: Supply score (current local supply)
// Y-axis: Demand score (projected global demand)
// Upper-left quadrant = high demand, low supply = market opportunity.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/market_gap.dart';

class MarketGapChart extends StatelessWidget {
  final List<MarketGap> gaps;

  const MarketGapChart({
    super.key,
    required this.gaps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bubble_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Gráfico de Brecha de Mercado',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Esquina superior izquierda = mayor oportunidad',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: gaps.isEmpty
                  ? Center(
                      child: Text(
                        'Sin datos para graficar',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : _buildChart(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    return ScatterChart(
      ScatterChartData(
        scatterSpots: _buildSpots(theme),
        minX: 0,
        maxX: 100,
        minY: 0,
        maxY: 100,
        borderData: FlBorderData(show: true),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: 25,
          verticalInterval: 25,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: Text(
              'Oferta Local →',
              style: theme.textTheme.bodySmall,
            ),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              '← Demanda Global',
              style: theme.textTheme.bodySmall,
            ),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        scatterTouchData: ScatterTouchData(
          enabled: true,
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipItems: (touchedSpot) {
              // Match gap by coordinates since ScatterSpot has no index.
              final match = gaps.where(
                (g) => g.supplyScore == touchedSpot.x && g.demandScore == touchedSpot.y,
              );
              if (match.isEmpty) return null;
              final gap = match.first;
              return ScatterTooltipItem(
                '${gap.niche}\nDemanda: ${gap.demandScore.toInt()}\nOferta: ${gap.supplyScore.toInt()}',
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }

  List<ScatterSpot> _buildSpots(ThemeData theme) {
    return gaps.asMap().entries.map((entry) {
      final gap = entry.value;
      final isOpportunity = gap.isHighOpportunity;

      return ScatterSpot(
        gap.supplyScore,
        gap.demandScore,
        dotPainter: FlDotCirclePainter(
          // Green for opportunities, amber for moderate, grey for low.
          color: isOpportunity
              ? theme.colorScheme.primary
              : gap.demandScore > 50
                  ? Colors.amber
                  : theme.colorScheme.outlineVariant,
          radius: isOpportunity ? 12 : 8,
          strokeWidth: 1,
          strokeColor: theme.colorScheme.outline,
        ),
      );
    }).toList();
  }
}
