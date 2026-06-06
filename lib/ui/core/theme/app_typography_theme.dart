import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:voicescribe_mobile/ui/core/theme/design_system.dart';

/// Premium app-wide type system.
///
/// Applies `Plus Jakarta Sans` (via `google_fonts`) on top of the Material 3
/// type scale, then re-applies the weight/tracking/height tuning the app already
/// relied on so nothing regresses. Display/headline roles get slightly tighter
/// tracking; body roles stay comfortable for long transcripts.
class AppTypographyTheme {
  const AppTypographyTheme._();

  /// The full tuned [TextTheme] for the given [brightness].
  ///
  /// `app_theme.dart` wires this in via `_textTheme(...)`.
  static TextTheme textTheme(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme;

    // Apply Plus Jakarta Sans across every role (preserves sizes/heights).
    final font = GoogleFonts.plusJakartaSansTextTheme(base);

    return TextTheme(
      displayLarge: font.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: font.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      displaySmall: font.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineLarge: font.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineMedium: font.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      headlineSmall: font.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: font.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: font.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: font.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: font.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: font.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: font.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: font.bodyLarge?.copyWith(height: AppTypography.bodyHeight),
      bodyMedium: font.bodyMedium?.copyWith(height: AppTypography.bodyHeight),
      bodySmall: font.bodySmall?.copyWith(height: 1.35),
    );
  }
}

/// Helpers for numeric values that must not reflow as digits change.
class AppTextStyles {
  const AppTextStyles._();

  static const List<ui.FontFeature> _tabular = [
    ui.FontFeature.tabularFigures(),
  ];

  /// Style for the live recording timer — large display weight with tabular
  /// figures so digits stay fixed-width while counting.
  static TextStyle timer(BuildContext context) {
    final theme = Theme.of(context);
    final base =
        theme.textTheme.displaySmall ??
        const TextStyle(fontSize: 36, fontWeight: FontWeight.w700);
    return base.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      fontFeatures: _tabular,
    );
  }

  /// Adds tabular figures to any numeric [base] style (durations, counts, etc.).
  static TextStyle numeric(TextStyle base) {
    return base.copyWith(fontFeatures: _tabular);
  }
}
