import 'package:flutter/material.dart';
import '../domain/price_simulation_result.dart';

/// Comparative Table UI (US03 AC2).
/// Displays User Cost vs Market Price.
class ComparativeTable extends StatelessWidget {
  final PriceSimulationResult result;

  const ComparativeTable({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHigh,
            child: Text(
              'Comparativa con el Mercado',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return DataTable(
                headingRowHeight: 40,
                // columnSpacing: 8,
                columns: [
                  DataColumn(label: Text('Métrica'), columnWidth: FixedColumnWidth(constraints.maxWidth/2)),
                  DataColumn(label: Text('Valor Estimado',), columnWidth: FixedColumnWidth(constraints.maxWidth/2)),
                ],
                rows: [
                  DataRow(cells: [
                    const DataCell(Text('Mi Costo Base')),
                    DataCell(Text('\$${result.userBaseCost.toStringAsFixed(2)}')),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text('Mi Precio Venta')),
                    DataCell(
                      Text(
                        '\$${result.userSalePrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text('Precio Promedio Mercado (IA)')),
                    DataCell(
                      Text(
                        '\$${result.marketAveragePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ]),
                ],
              );
            }
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.insights, size: 20, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.insights,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
