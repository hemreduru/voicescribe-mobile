import 'package:flutter/material.dart';

import 'package:voicescribe_mobile/ui/core/theme/premium_tokens.dart';

/// Formalizes the premium token layer (brand accents, layered surfaces and
/// scheme-derived gradients) as a [ThemeExtension] so it travels inside
/// [ThemeData] and animates across light/dark transitions.
///
/// Resolved from the active [ColorScheme] via [BrandTokens.of] and read through
/// the `context.brand` accessor (see [BrandContext]). The underlying
/// `AppAccents/AppSurfaces/AppGradients.of(scheme)` factories remain public and
/// valid — this type simply bundles and lerps them.
@immutable
class BrandTokens extends ThemeExtension<BrandTokens> {
  const BrandTokens({
    required this.accents,
    required this.surfaces,
    required this.gradients,
  });

  /// Resolves every brand token from the active [scheme].
  factory BrandTokens.of(ColorScheme scheme) => BrandTokens(
    accents: AppAccents.of(scheme),
    surfaces: AppSurfaces.of(scheme),
    gradients: AppGradients.of(scheme),
  );

  /// Brand + reserved-recording accent colors.
  final AppAccents accents;

  /// Layered surface colors (base wash, raised, elevated, hairline).
  final AppSurfaces surfaces;

  /// Brand, recording and ambient gradients.
  final AppGradients gradients;

  @override
  BrandTokens copyWith({
    AppAccents? accents,
    AppSurfaces? surfaces,
    AppGradients? gradients,
  }) {
    return BrandTokens(
      accents: accents ?? this.accents,
      surfaces: surfaces ?? this.surfaces,
      gradients: gradients ?? this.gradients,
    );
  }

  @override
  BrandTokens lerp(covariant BrandTokens? other, double t) {
    if (other == null) return this;
    return BrandTokens(
      accents: accents.lerp(other.accents, t),
      surfaces: surfaces.lerp(other.surfaces, t),
      gradients: gradients.lerp(other.gradients, t),
    );
  }
}

/// `context.brand` — the resolved [BrandTokens] for the current theme.
extension BrandContext on BuildContext {
  /// Falls back to deriving tokens from the active [ColorScheme] when the
  /// extension isn't registered (e.g. a test harness or a bare [ThemeData]),
  /// so it is exactly as robust as the `AppX.of(scheme)` factories it replaced.
  BrandTokens get brand {
    final theme = Theme.of(this);
    return theme.extension<BrandTokens>() ?? BrandTokens.of(theme.colorScheme);
  }
}
