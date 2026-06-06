import 'package:flutter/material.dart';

import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/theme/premium_tokens.dart';

/// Layout-only, state-agnostic master/detail scaffold.
///
/// On wide layouts (own width ≥ [twoPaneBreakpoint], or [isTwoPane] forced) it
/// shows the [master] beside a live detail pane separated by a hairline divider,
/// with an [AnimatedSwitcher] transition between selections and a tasteful
/// [emptyState] when nothing is selected. On compact layouts it renders only the
/// [master] — callers handle detail via their existing pushed/modal route.
///
/// Honors [MediaQueryData.disableAnimations] (no switch animation when reduced).
class AdaptiveMasterDetail<T> extends StatelessWidget {
  const AdaptiveMasterDetail({
    required this.master,
    required this.selected,
    required this.detailBuilder,
    required this.emptyState,
    super.key,
    this.isTwoPane,
    this.masterWidth = AppPanes.masterWidth,
    this.twoPaneBreakpoint = AppPanes.twoPaneBreakpoint,
    this.detailKey,
  });

  /// The persistent master (list) pane.
  final Widget master;

  /// The currently-selected value, or null when nothing is open.
  final T? selected;

  /// Builds the detail pane for a non-null selection.
  final Widget Function(BuildContext context, T value) detailBuilder;

  /// Shown in the detail pane when [selected] is null.
  final Widget emptyState;

  /// Forces two-pane on/off. When null, decided from the own constraints.
  final bool? isTwoPane;

  final double masterWidth;
  final double twoPaneBreakpoint;

  /// Optional key for the detail subtree so the [AnimatedSwitcher] transitions
  /// when the selection changes. Defaults to `ValueKey(value)`.
  final Key Function(T value)? detailKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoPane = isTwoPane ?? constraints.maxWidth >= twoPaneBreakpoint;
        if (!twoPane) {
          return master;
        }

        final scheme = Theme.of(context).colorScheme;
        final surfaces = AppSurfaces.of(scheme);
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        final value = selected;
        final Widget detail = value == null
            ? KeyedSubtree(key: const ValueKey('__empty__'), child: emptyState)
            : KeyedSubtree(
                key: detailKey?.call(value) ?? ValueKey(value),
                child: detailBuilder(context, value),
              );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: masterWidth, child: master),
            VerticalDivider(
              width: AppPanes.dividerThickness,
              thickness: AppPanes.dividerThickness,
              color: surfaces.hairline,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : AppMotion.normal,
                switchInCurve: AppMotionX.expressive,
                child: detail,
              ),
            ),
          ],
        );
      },
    );
  }
}
