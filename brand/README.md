# VoiceScribe — Brand

The consolidated brand identity for VoiceScribe, built around one ownable hue —
**Signal Teal** — and the product's defining promise: *your voice never leaves
your device.*

```
brand/
├── STRATEGY.md              Verbal identity (essence, archetype, voice, taglines)
├── BRAND_GUIDELINES.html    Self-contained guidelines (dark toggle, print-ready)
├── tokens/
│   └── brand-tokens.json    DTCG tokens — single source of truth for colour/space/motion
├── logo/
│   ├── icon-mark-color.svg  Aperture Wave mark (full colour, self-grounding)
│   ├── icon-mark-mono.svg   Single-colour knockout (currentColor)
│   ├── wordmark-{light,dark}.svg
│   ├── lockup-{light,dark}.svg
│   └── concepts.svg         Three explored directions (A = recommended)
└── app_icon/
    ├── foreground.svg / background.svg / icon-master.svg   Design sources
    └── generated/           PNG masters + previews (built, see below)
```

## The colour decision (why teal)

The brand colour was previously **split**: `design_system.dart` used a generic
Tailwind blue (`#2563EB`) as `ColorScheme.primary`, while `premium_tokens.dart`
called an indigo "glow" (`#6E78FF`) *the brand accent* — and `AppGradients.brand`
literally blended the two. Both are retired and reconciled into **Signal Teal**:

- **Privacy = trust (blue) + safe/permission (green)** — teal is their intersection.
- It is the **optical complement of the reserved recording-red**, so the UI tells
  one calm teal story and red *only* ever means "recording."
- It is **unclaimed** in the transcription category (Otter = blue, Fireflies =
  purple) and avoids the generic "AI blue/purple."

## Token → Flutter theme mapping

`tokens/brand-tokens.json` is the documented source of truth; the Dart theme
mirrors it.

| Token | Flutter location | Value |
|---|---|---|
| `brand.teal.700` | `AppColors.primary` / light `ColorScheme.primary` | `#0B7884` |
| `brand.teal.300` | dark `ColorScheme.primary`, `surfaceTint`, light `inversePrimary` | `#5FE3DC` |
| `brand.teal.100` | light `primaryContainer` | `#D9F7F4` |
| `brand.teal.800` | dark `primaryContainer` | `#0E565C` |
| `brand.glow` (teal.500 / .300) | `AppAccents.glow` light / dark | `#119A91` / `#5FE3DC` |
| `functional.success.default` | `AppColors.success` / `AppTheme.positive` | `#15803D` (was teal — moved to green) |
| `reserved.recording` | `AppAccents.recording` | `#FF4D4D` / `#FF5C5C` (unchanged) |
| `spacing.*`, `radius.*`, `motion.*` | `AppSpacing`, `AppRadii`, `AppMotion`, `AppMotionX` | mirrored |

The premium token layer (`AppAccents` / `AppSurfaces` / `AppGradients`) is now
exposed as a `ThemeExtension` — **`BrandTokens`** (`lib/ui/core/theme/brand_tokens.dart`),
registered in `AppTheme.light()/dark()` and read via **`context.brand`**
(`context.brand.accents` / `.surfaces` / `.gradients`). The original
`AppX.of(scheme)` factories still work.

Verify contrast at any time:

```bash
dart run tool/check_contrast.dart      # prints WCAG ratios for every role pair
```

## Regenerate the app icon

PNG masters are rendered from the design sources with the Flutter SDK (no system
rasterizer needed), then handed to `flutter_launcher_icons`:

```bash
# 1. Render PNG masters → brand/app_icon/generated/ (also a 24px legibility check)
flutter test tool/generate_app_icons_test.dart

# 2. Generate Android (adaptive + legacy) and iOS launcher icons
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
```

Do **not** hand-edit the generated `android/app/src/main/res/**` or
`ios/Runner/Assets.xcassets/**` icon files — re-run the commands above instead.

## Codegen

This brand work touches **no `freezed` / `json_serializable` models**, so
`build_runner` is **not** required here. Only run it after editing an annotated
model:

```bash
dart run build_runner build --delete-conflicting-outputs
```
