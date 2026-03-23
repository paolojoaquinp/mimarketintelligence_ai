import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A custom floating bottom navigation bar with glassmorphism effect.
/// 
/// This widget displays a pill-shaped navigation bar at the bottom of the screen
/// with animated indicator that moves between tabs.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, top: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBackground(
              child: Container(
                height: 62,
                width: 300, // Adjusted for 3 tabs
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated Indicator
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          alignment: _getAlignment(currentIndex),
                          child: Container(
                            width: constraints.maxWidth / 3,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(70),
                            ),
                          ),
                        ),
                        // Buttons
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildNavButton(
                              constraints,
                              Icons.description_outlined,
                              'Reportes',
                              0,
                            ),
                            _buildNavButton(
                              constraints,
                              Icons.analytics_outlined,
                              'Nichos',
                              1,
                            ),
                            _buildNavButton(
                              constraints,
                              Icons.price_check_outlined,
                              'Simulador',
                              2,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(70),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceBright.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(70),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(offset: Offset(1, 1), spreadRadius: 2.0, color: AppColors.onSecondaryContainer)
            ]
          ),
          child: child,
        ),
      ),
    );
  }

  Alignment _getAlignment(int index) {
    switch (index) {
      case 0:
        return const Alignment(-1.0, 0.0);
      case 1:
        return const Alignment(0.0, 0.0);
      case 2:
        return const Alignment(1.0, 0.0);
      default:
        return const Alignment(-1.0, 0.0);
    }
  }

  Widget _buildNavButton(
    BoxConstraints constraints,
    IconData icon,
    String label,
    int index,
  ) {
    final bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: constraints.maxWidth / 3,
        height: 62,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.primary
                  : AppColors.outline,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive 
                    ? AppColors.primary 
                    : AppColors.outline,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
