import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class GeminiHeaderWidget extends StatelessWidget {
  final String fileName;

  const GeminiHeaderWidget({
    super.key,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // According to Figma, Title is "Analista Gemini"
    // "Modo Activo" badge.
    // Subtitle references the file.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        Container(
          padding: EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            color: AppColors.secondary.withOpacity(0.3),
          ),
          child: RichText(
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF43474F),
              ),
              children: [
                const TextSpan(text: 'Consultoría en tiempo real sobre el reporte\\nde mercado '),
                TextSpan(
                  text: '"$fileName"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
