/// Application theme configuration using Material Design 3.
///
/// Centralizes all visual tokens (colors, typography, shapes) to ensure
/// consistency across the app and simplify future theming changes.
///
/// Colors and typography are sourced from the Stitch design system
/// ("Arquitectura MiEstudioMarket AI (SDD)" project).
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.lightColorScheme,
      textTheme: AppTypography.textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
