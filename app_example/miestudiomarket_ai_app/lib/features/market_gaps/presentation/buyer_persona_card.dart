/// Expandable Buyer Persona card (US02 AC3).
library;
import 'package:flutter/material.dart';

import '../domain/market_gap.dart';

class BuyerPersonaCard extends StatelessWidget {
  final MarketGap gap;

  const BuyerPersonaCard({super.key, required this.gap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final persona = gap.buyerPersona;

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: gap.isHighOpportunity
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.person,
            color: gap.isHighOpportunity
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(gap.niche, style: theme.textTheme.titleSmall),
        subtitle: Text(
          'Demanda: ${gap.demandScore.toInt()} | Oferta: ${gap.supplyScore.toInt()}',
          style: theme.textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Opportunity description
                Text(gap.opportunity, style: theme.textTheme.bodyMedium,textAlign: TextAlign.justify,),
                const Divider(height: 24),

                // Buyer Persona header
                Text('Buyer Persona: ${persona.niche}',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _buildInfoRow(
                  theme,
                  Icons.people,
                  'Demografía',
                  persona.demographics,
                ),
                _buildInfoRow(
                  theme,
                  Icons.shopping_cart,
                  'Comportamiento',
                  persona.buyingBehavior,
                ),
                const SizedBox(height: 12),

                // Pain points
                _buildTagSection(
                  theme,
                  'Puntos de Dolor',
                  Icons.warning_amber,
                  persona.painPoints,
                  theme.colorScheme.errorContainer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          Row(children: 
            [
              Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.justify,),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text(value, textAlign: TextAlign.justify,)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagSection(
    ThemeData theme,
    String title,
    IconData icon,
    List<String> items,
    Color chipColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(title,
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: items
              .map((item) => Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(item, style: theme.textTheme.labelSmall,),
                    // backgroundColor: chipColor,
                    // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    // visualDensity: VisualDensity.compact,
                  ))
              .toList(),
        ),
      ],
    );
  }
}
