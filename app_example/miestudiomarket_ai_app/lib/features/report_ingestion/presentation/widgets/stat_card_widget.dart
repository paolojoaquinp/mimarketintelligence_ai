import 'package:flutter/material.dart';
import 'package:miestudiomarket_ai_app/core/theme/app_colors.dart';

class StatCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color backgroundColor;
  final Color titleColor;
  final Color valueColor;
  final Color subtitleColor;
  final IconData? icon;
  final double? progressValue;

  const StatCardWidget({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.backgroundColor,
    required this.titleColor,
    required this.valueColor,
    required this.subtitleColor,
    this.icon,
    this.progressValue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: double.infinity,
        width: double.infinity,
        color: backgroundColor,
        child: Stack(
          children: [
            // Placeholder for background image asset
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(
                Icons.bubble_chart,
                size: 140,
                color: valueColor.withValues(alpha: 0.1),
              ),
            ),
            
            // Top-left progress indicator and icon
            Positioned(
              top: 16,
              left: 16,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progressValue ?? 0.65, // Default placeholder
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.6),
                      valueColor: AlwaysStoppedAnimation<Color>(valueColor),
                    ),
                    Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon ?? Icons.analytics_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Centered content
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 24.0), // balances top-left icon
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}