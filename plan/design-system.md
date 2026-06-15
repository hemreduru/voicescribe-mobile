# VoiceScribe — Design System Reference

> Extracted 2026-06-15 from `lib/ui/core/theme/` + `lib/ui/core/widgets/`.
> **This is the contract.** Every new screen MUST reuse these tokens and shared
> widgets. Do not introduce new colors, fonts, spacing values, radii, shadows or
> bespoke buttons/cards/inputs. If something is missing, extend the token layer
> here first, then use it.

---

## 1. Color (`design_system.dart` → `AppColors`, `premium_tokens.dart`)

Brand is a single ownable hue — **Signal Teal**. Recording-red is reserved
exclusively for the live-mic state.

| Token | Value | Use |
|---|---|---|
| `AppColors.primary` | `#0B7884` | Brand primary, CTAs, active nav |
| `AppColors.secondary` | `#0E6E84` | Secondary brand |
| `AppColors.accent` | `#F97316` (orange) | Sparing accent |
| `AppColors.success` | `#15803D` | Ready/completed |
| `AppColors.warning` | `#D97706` | Processing/caution |
| `AppColors.danger` | `#DC2626` | Errors/destructive |
| `AppColors.ink` | `#1E293B` | Primary text |
| `AppColors.border` | `#E2E8F0` | Hairlines (light) |
| `AppColors.canvas` | `#F8FAFC` | Page background (light) |

**Brand tokens via `context.brand`** (ThemeExtension `BrandTokens`, lerps across
light/dark):
- `context.brand.accents.recording` (~`#FF4D4D`) — **only** for live recording.
- `context.brand.accents.glow` — Signal Teal luminous accent.
- `context.brand.surfaces.{base,raised,elevated,hairline}` — layered surfaces
  (dark base is `#080A0F`, not pure black).
- `context.brand.gradients.{brand,recording,ambient}` — scheme-derived gradients;
  `ambient` powers `AmbientBackdrop`.

Status colors come from `statusColor(context, status)` (transcript_screen.dart):
active→error, processing→amber, ready→positive, issue→error. Reuse this, never
re-pick.

---

## 2. Typography (`app_typography_theme.dart`)

- Font: **Plus Jakarta Sans** (`google_fonts`) applied over the M3 type scale.
- Display/headline/title/label roles → `FontWeight.w700`; label small/medium
  w600; body roles keep comfortable height (`AppTypography.bodyHeight = 1.42`).
- Display/headline get negative letter-spacing (−0.2…−0.5).
- Numeric/timer values: `AppTextStyles.timer(context)` / `AppTextStyles.numeric()`
  → tabular figures so digits don't reflow.
- Read type via `Theme.of(context).textTheme.*`. Never hardcode `TextStyle(fontSize:)`.

---

## 3. Spacing / radius / motion / layout (`design_system.dart`)

- **Spacing** `AppSpacing`: xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · xxxl 40.
- **Radius** `AppRadii`: xs 6 · sm 10 · md 12 · lg 16 · xl 20 · pill 999.
- **Motion** `AppMotion`: instant 90ms · fast 150 · normal 240 · slow 320;
  `standardCurve` easeOutCubic, `emphasizedCurve` easeInOutCubic. Premium:
  `AppMotionX.expressive` Cubic(0.16,1,0.3,1), `entrance` 420ms, `spring`.
- **Elevation** `AppElevation.{card,soft,glass}(color)` — use these, no ad-hoc shadows.
- **Layout** `AppLayout`: breakpoints compact 600 / medium 900 / expanded 1200;
  `maxContentWidth` 960, `maxFormWidth` 560, `minTouchTarget` 48; responsive
  `horizontalPadding(width)`, `pageInsetsFor`, `modalInsetsFor`.
- **Panes** `AppPanes`: master 368, `twoPaneBreakpoint` 1000, divider 1.

---

## 4. Haptics (`AppHaptics`)

Intent-named, used **sparsely**: `light/medium/selection/success/warning`.
Already wired on the record button (medium start / warning stop) and list
selection. New primary actions should reuse these, not call `HapticFeedback` raw.

---

## 5. Shared widgets (`lib/ui/core/widgets/`) — reuse, don't reinvent

| Widget | Purpose |
|---|---|
| `AppButton` (+`AppButtonGroup`) | Variants: primary/tonal/outline; `isLoading`, `expanded`, `icon`. The one button. |
| `AppCard` | Surface card; `selected`, `onTap`, `semanticLabel`. |
| `AppTextField` / `AppSearchField` | Inputs with prefix icon. |
| `AppPage` / `AppConstrainedBody` / `AppPageListView` / `AppModalListView` / `AppModalBody` | Page + modal scaffolding, max-width clamping. |
| `AppSection` / `SectionHeader` | Titled sections with optional subtitle. |
| `AppSegmentedControl` / `AppSegment` | Sort/filter toggles. |
| `AppSkeleton` / `AppSkeletonList` | Shimmer placeholders for first load. |
| `AmbientBackdrop` | Ambient-gradient page background (used on recording). |
| `PulseRecordButton` | The mic button (pulse animation + haptics). |
| `AudioVisualizer` | Live waveform from audio level. |
| `AdaptiveMasterDetail` | Two-pane (master/detail) on wide layouts. |
| `GlobalSyncFeedbackHost` | App-wide sync feedback surface. |
| premium_widgets.dart | `EmptyState`, `MetricPill`, `StatusPill`, `AppIconBadge`, `AppDurationDisplay`, `AppEditableTitle`, `AppSelectionBar`, `PremiumDivider`, `AppErrorText`. |

**Empty states** must use `EmptyState(icon,title,description)` — never a bare
`Text` on a white screen (the recording screen's "no recordings" is currently a
plain card — candidate to migrate).

---

## 6. Navigation (`app_shell.dart`, `app_router.dart`)

- `go_router` with `StatefulShellRoute.indexedStack`; 4 branches:
  `/recording` · `/transcript` · `/ai` · `/settings`.
- Compact (<900): `AppBottomNavigation`. Medium+: `AppSideNavigationRail`
  (extended ≥1200). Destinations defined once in `AppShell`.
- `/` = `BootstrapGate`, `/auth` = `AuthScreen`. Redirects gate on
  bootstrap-initialized → authenticated → bootstrap-ready.
- Page transitions: 240ms fade (`_fadePage`).

**Onboarding (Phase 3) must slot in here**: a new gated route before
`/recording`, driven by a persisted "seen" flag, reusing this fade + shell-less
full-screen pattern (like `/auth`).

---

## 7. i18n

- ARB-based: `lib/l10n/app_en.arb` + `app_tr.arb` (291 keys each), generated to
  `app_localizations*.dart`. Access via `context.l10n`.
- Error strings use machine-readable `AppErrorCode` mapped through
  `error_messages.dart` (`code.localized(l10n)`).
- **Rule:** every user-visible string is added to BOTH arb files. No hardcoded
  strings. (Known violation to fix: `_statusHelpDescription` in
  `transcript_screen.dart:1212` hardcodes TR/EN.)

---

## 8. Do / Don't

- ✅ `Theme.of(context)`, `context.brand`, `context.l10n`, `AppX` tokens, shared widgets.
- ✅ Honor `themeMode` (system/light/dark) — all tokens already resolve per scheme.
- ❌ New hex colors, raw `TextStyle(fontSize:)`, magic padding numbers, custom
  buttons/cards, raw `HapticFeedback`, hardcoded English/Turkish.
