/// Official Stitch design system color tokens (Material Design 3).
///
/// These values were extracted from the Stitch project
/// "Arquitectura MiEstudioMarket AI (SDD)" and must remain
/// the single source of truth for every color in the app.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary ──────────────────────────────────────────────
  static const primary = Color(0xFF00193C);
  static const primaryContainer = Color(0xFF002D62);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF7796D1);

  // ── Secondary ────────────────────────────────────────────
  static const secondary = Color(0xFF50606F);
  static const secondaryContainer = Color(0xFFD1E1F4);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF556474);

  // ── Tertiary ─────────────────────────────────────────────
  static const tertiary = Color(0xFF001F0B);
  static const tertiaryContainer = Color(0xFF003718);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF2EAB5F);

  // ── Error ────────────────────────────────────────────────
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onError = Color(0xFFFFFFFF);
  static const onErrorContainer = Color(0xFF93000A);

  // ── Surface & Background ─────────────────────────────────
  static const surface = Color(0xFFF9F9FC);
  static const surfaceDim = Color(0xFFDADADC);
  static const surfaceBright = Color(0xFFF9F9FC);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F3F6);
  static const surfaceContainer = Color(0xFFEEEEF0);
  static const surfaceContainerHigh = Color(0xFFE8E8EA);
  static const surfaceContainerHighest = Color(0xFFE2E2E5);
  static const onSurface = Color(0xFF1A1C1E);
  static const onSurfaceVariant = Color(0xFF43474F);

  // ── Outline ──────────────────────────────────────────────
  static const outline = Color(0xFF747781);
  static const outlineVariant = Color(0xFFC4C6D1);

  // ── Inverse ──────────────────────────────────────────────
  static const inverseSurface = Color(0xFF2F3133);
  static const inverseOnSurface = Color(0xFFF0F0F3);
  static const inversePrimary = Color(0xFFABC7FF);

  // ── Surface tint ─────────────────────────────────────────
  static const surfaceTint = Color(0xFF3E5E95);

  // ── Fixed accent tokens (app-specific) ───────────────────
  static const primaryFixed = Color(0xFFD7E2FF);
  static const primaryFixedDim = Color(0xFFABC7FF);
  static const secondaryFixed = Color(0xFFD4E4F6);
  static const secondaryFixedDim = Color(0xFFB8C8DA);
  static const tertiaryFixed = Color(0xFF83FBA5);
  static const tertiaryFixedDim = Color(0xFF66DD8B);

  // ── Convenience: explicit ColorScheme ────────────────────

  /// Pre-built light [ColorScheme] using the exact Stitch tokens.
  ///
  /// Why explicit over seed-based: guarantees pixel-perfect color fidelity
  /// with the approved Stitch design system, avoiding any algorithmic drift.
  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: inverseSurface,
    onInverseSurface: inverseOnSurface,
    inversePrimary: inversePrimary,
    surfaceTint: surfaceTint,
    surfaceDim: surfaceDim,
    surfaceBright: surfaceBright,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
  );
}
