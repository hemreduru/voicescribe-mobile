import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:voicescribe_mobile/ui/core/theme/design_system.dart';

/// Premium token layer — additive helpers derived from the active
/// [ColorScheme]. These extend (never replace) the base tokens in
/// `design_system.dart`. Everything resolves correctly in light + dark because
/// it is computed from the scheme passed in.

/// Brand and state accent colors.
///
/// `recording` (≈#FF4D4D) is reserved exclusively for the live-mic state so its
/// appearance always means "recording". `glow` is the calm indigo brand accent.
class AppAccents {
  const AppAccents({required this.recording, required this.glow});

  factory AppAccents.of(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    return AppAccents(
      recording: dark ? const Color(0xFFFF5C5C) : const Color(0xFFFF4D4D),
      glow: dark ? const Color(0xFF8C94FF) : const Color(0xFF6E78FF),
    );
  }

  /// Reserved recording-red. Do not use as a general primary.
  final Color recording;

  /// Indigo brand glow accent.
  final Color glow;
}

/// Layered surface colors: a base wash, raised cards, elevated sheets and a
/// hairline border. Dark mode uses a deep (not pure-black) base; light mode
/// stays subtle.
class AppSurfaces {
  const AppSurfaces({
    required this.base,
    required this.raised,
    required this.elevated,
    required this.hairline,
  });

  factory AppSurfaces.of(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    if (dark) {
      return AppSurfaces(
        base: const Color(0xFF080A0F),
        raised: Color.alphaBlend(
          Colors.white.withValues(alpha: 0.04),
          scheme.surface,
        ),
        elevated: Color.alphaBlend(
          Colors.white.withValues(alpha: 0.07),
          scheme.surface,
        ),
        hairline: Colors.white.withValues(alpha: 0.08),
      );
    }
    return AppSurfaces(
      base: scheme.surface,
      raised: scheme.surface,
      elevated: Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.02),
        scheme.surface,
      ),
      hairline: scheme.outlineVariant,
    );
  }

  final Color base;
  final Color raised;
  final Color elevated;
  final Color hairline;
}

/// Scheme-derived gradients for brand surfaces, the recording state, and the
/// ambient backdrop.
class AppGradients {
  const AppGradients({
    required this.brand,
    required this.recording,
    required this.ambient,
  });

  factory AppGradients.of(ColorScheme scheme) {
    final accents = AppAccents.of(scheme);
    final surfaces = AppSurfaces.of(scheme);
    return AppGradients(
      brand: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accents.glow, scheme.primary],
      ),
      recording: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accents.recording,
          Color.alphaBlend(
            Colors.black.withValues(alpha: 0.18),
            accents.recording,
          ),
        ],
      ),
      ambient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(accents.glow.withValues(alpha: 0.05), surfaces.base),
          surfaces.base,
        ],
      ),
    );
  }

  final Gradient brand;
  final Gradient recording;
  final Gradient ambient;
}

/// Expressive motion tokens extending [AppMotion] for premium widgets.
class AppMotionX {
  const AppMotionX._();

  /// Signature easing — fast, decisive settle.
  static const Cubic expressive = Cubic(0.16, 1, 0.3, 1);

  /// Default staggered-entrance duration.
  static const Duration entrance = Duration(milliseconds: 420);

  /// Spring used for tactile press-scale feedback.
  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 24,
  );
}

/// Intent-named haptics for primary controls. Keep usage sparse.
class AppHaptics {
  const AppHaptics._();

  static void light() => HapticFeedback.lightImpact();

  static void medium() => HapticFeedback.mediumImpact();

  static void selection() => HapticFeedback.selectionClick();

  static void success() => HapticFeedback.lightImpact();

  static void warning() => HapticFeedback.heavyImpact();
}

/// Constants for the adaptive two-pane (master/detail) layout.
class AppPanes {
  const AppPanes._();

  /// Master list width on wide layouts.
  static const double masterWidth = 368;

  /// Minimum width at which the detail pane shows beside the master. Evaluated
  /// against the layout's own constraints (not the device width), so it accounts
  /// for the navigation rail already consuming horizontal space.
  static const double twoPaneBreakpoint = 1000;

  /// Hairline divider thickness between panes.
  static const double dividerThickness = 1;
}
