import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:voicescribe_mobile/shared/theme/design_system.dart';

export 'package:voicescribe_mobile/shared/theme/design_system.dart';

class AppTheme {
  static const Color rose = AppColors.danger;
  static const Color violet = AppColors.secondary;
  static const Color teal = AppColors.success;
  static const Color amber = AppColors.warning;
  static const Color slate = AppColors.ink;

  static ThemeData light() {
    _configureFonts();
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCE8FF),
      onPrimaryContainer: Color(0xFF0D2A66),
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE4ECFF),
      onSecondaryContainer: Color(0xFF122A58),
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFFE4D3),
      onTertiaryContainer: Color(0xFF6F2E00),
      error: AppColors.danger,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: Color(0xFF475569),
      outline: Color(0xFFB7C6DB),
      outlineVariant: AppColors.border,
      shadow: Color(0x1A0F172A),
      scrim: Color(0x520F172A),
      inverseSurface: Color(0xFF0F172A),
      onInverseSurface: Color(0xFFF8FAFC),
      inversePrimary: Color(0xFF8CB4FF),
      surfaceTint: AppColors.primary,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    _configureFonts();
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF8CB4FF),
      onPrimary: Color(0xFF082763),
      primaryContainer: Color(0xFF13387C),
      onPrimaryContainer: Color(0xFFDCE8FF),
      secondary: Color(0xFFB5CBFF),
      onSecondary: Color(0xFF08275D),
      secondaryContainer: Color(0xFF1A3A7A),
      onSecondaryContainer: Color(0xFFE4ECFF),
      tertiary: Color(0xFFFFBB8C),
      onTertiary: Color(0xFF612400),
      tertiaryContainer: Color(0xFF8F3A00),
      onTertiaryContainer: Color(0xFFFFE4D3),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: Color(0xFF0D1118),
      onSurface: Color(0xFFE7EDF8),
      onSurfaceVariant: Color(0xFF9FB0C8),
      outline: Color(0xFF5E6E86),
      outlineVariant: Color(0xFF344158),
      shadow: Color(0x66000000),
      scrim: Color(0x66000000),
      inverseSurface: Color(0xFFE7EDF8),
      onInverseSurface: Color(0xFF111826),
      inversePrimary: AppColors.primary,
      surfaceTint: Color(0xFF8CB4FF),
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final radius = BorderRadius.circular(AppRadii.md);
    final textTheme = _textTheme(scheme.brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.brightness == Brightness.dark
          ? Color.alphaBlend(const Color(0x14000000), scheme.surface)
          : Color.alphaBlend(
              AppColors.primary.withValues(alpha: 0.02),
              AppColors.canvas,
            ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: scheme.brightness == Brightness.dark
            ? scheme.surface.withValues(alpha: 0.94)
            : scheme.surface.withValues(alpha: 0.96),
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.88),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: states.contains(WidgetState.selected) ? 23 : 22,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            letterSpacing: 0.1,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.96),
        elevation: 0,
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.88),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 23),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 22,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.brightness == Brightness.dark
            ? scheme.surface.withValues(alpha: 0.72)
            : scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, AppLayout.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, AppLayout.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          side: BorderSide(color: scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppLayout.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppLayout.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant.withValues(alpha: 0.52),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        titleTextStyle: textTheme.titleSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.outlineVariant,
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.86),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
    );
  }

  static void _configureFonts() {
    // Keep typography deterministic in tests and offline mode.
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme;

    return TextTheme(
      displayLarge: GoogleFonts.poppins(
        textStyle: base.displayLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: AppTypography.letterSpacing,
      ),
      displayMedium: GoogleFonts.poppins(
        textStyle: base.displayMedium,
        fontWeight: FontWeight.w700,
        letterSpacing: AppTypography.letterSpacing,
      ),
      displaySmall: GoogleFonts.poppins(
        textStyle: base.displaySmall,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.poppins(
        textStyle: base.headlineLarge,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.poppins(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.poppins(
        textStyle: base.headlineSmall,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.poppins(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.poppins(
        textStyle: base.titleMedium,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: GoogleFonts.poppins(
        textStyle: base.titleSmall,
        fontWeight: FontWeight.w700,
      ),
      labelLarge: GoogleFonts.sourceSans3(
        textStyle: base.labelLarge,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: GoogleFonts.sourceSans3(
        textStyle: base.labelMedium,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: GoogleFonts.sourceSans3(
        textStyle: base.labelSmall,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.sourceSans3(
        textStyle: base.bodyLarge,
        height: AppTypography.bodyHeight,
      ),
      bodyMedium: GoogleFonts.sourceSans3(
        textStyle: base.bodyMedium,
        height: AppTypography.bodyHeight,
      ),
      bodySmall: GoogleFonts.sourceSans3(
        textStyle: base.bodySmall,
        height: 1.35,
      ),
    );
  }
}
