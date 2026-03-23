/// Typography definitions using Google Fonts (Manrope + Inter).
///
/// Mirrors the Stitch design system where Manrope is used for
/// display/headline/title styles and Inter for body/label styles.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  /// Complete [TextTheme] matching the Stitch design system.
  ///
  /// Manrope → display, headline, title (impactful, brand-forward).
  /// Inter   → body, label (neutral, highly readable).
  static TextTheme get textTheme {
    final manrope = GoogleFonts.manropeTextTheme();
    final inter = GoogleFonts.interTextTheme();

    return TextTheme(
      // ── Display ──
      displayLarge: manrope.displayLarge!.copyWith(fontWeight: FontWeight.w800),
      displayMedium: manrope.displayMedium!.copyWith(fontWeight: FontWeight.w800),
      displaySmall: manrope.displaySmall!.copyWith(fontWeight: FontWeight.w700),

      // ── Headline ──
      headlineLarge: manrope.headlineLarge!.copyWith(fontWeight: FontWeight.w800),
      headlineMedium: manrope.headlineMedium!.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: manrope.headlineSmall!.copyWith(fontWeight: FontWeight.w700),

      // ── Title ──
      titleLarge: manrope.titleLarge!.copyWith(fontWeight: FontWeight.w700),
      titleMedium: manrope.titleMedium!.copyWith(fontWeight: FontWeight.w600),
      titleSmall: manrope.titleSmall!.copyWith(fontWeight: FontWeight.w600),

      // ── Body ──
      bodyLarge: inter.bodyLarge!.copyWith(fontWeight: FontWeight.w400),
      bodyMedium: inter.bodyMedium!.copyWith(fontWeight: FontWeight.w400),
      bodySmall: inter.bodySmall!.copyWith(fontWeight: FontWeight.w400),

      // ── Label ──
      labelLarge: inter.labelLarge!.copyWith(fontWeight: FontWeight.w600),
      labelMedium: inter.labelMedium!.copyWith(fontWeight: FontWeight.w500),
      labelSmall: inter.labelSmall!.copyWith(fontWeight: FontWeight.w500),
    );
  }
}
