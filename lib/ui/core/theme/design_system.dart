import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color accent = Color(0xFFF97316);
  static const Color success = Color(0xFF0F766E);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  static const Color ink = Color(0xFF1E293B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color canvas = Color(0xFFF8FAFC);
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

class AppRadii {
  const AppRadii._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}

class AppMotion {
  const AppMotion._();

  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubic;
}

class AppLayout {
  const AppLayout._();

  static const double compactWidth = 600;
  static const double mediumWidth = 900;
  static const double expandedWidth = 1200;
  static const double maxContentWidth = 960;
  static const double maxFormWidth = 560;
  static const double minTouchTarget = 48;

  static const double minHorizontalPadding = AppSpacing.lg;
  static const double mediumHorizontalPadding = AppSpacing.xl;
  static const double maxHorizontalPadding = AppSpacing.xxl;

  static const double pageTopInset = AppSpacing.sm;
  static const double pageBottomInset = AppSpacing.xl;

  static bool isCompact(double width) => width < compactWidth;

  static double horizontalPadding(double width) {
    if (width >= expandedWidth) {
      return maxHorizontalPadding;
    }
    if (width >= mediumWidth) {
      return mediumHorizontalPadding;
    }
    return minHorizontalPadding;
  }

  static double maxReadableWidth(double width) {
    final available = width - (horizontalPadding(width) * 2);
    return math.min(maxContentWidth, available);
  }

  static double maxModalWidth(double width) {
    final horizontal = horizontalPadding(width);
    return math.min(maxContentWidth + (horizontal * 2), width);
  }

  static EdgeInsets pageInsetsFor(double width) {
    return EdgeInsets.symmetric(horizontal: horizontalPadding(width));
  }

  static EdgeInsets modalInsetsFor(double width) {
    return EdgeInsets.fromLTRB(
      horizontalPadding(width),
      0,
      horizontalPadding(width),
      AppSpacing.xl,
    );
  }
}

class AppTypography {
  const AppTypography._();

  static const double bodyHeight = 1.42;
  static const double relaxedBodyHeight = 1.5;
  static const double compactLabelHeight = 1.18;
  static const double letterSpacing = 0;
}

class AppElevation {
  const AppElevation._();

  static List<BoxShadow> card(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.055),
      blurRadius: 18,
      spreadRadius: -10,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> soft(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.06),
      blurRadius: 24,
      spreadRadius: -6,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> glass(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.09),
      blurRadius: 30,
      spreadRadius: -10,
      offset: const Offset(0, 18),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.05),
      blurRadius: 1,
      offset: const Offset(0, 1),
    ),
  ];
}
