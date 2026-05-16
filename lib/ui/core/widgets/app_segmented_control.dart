import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_card.dart';

class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.segments,
    required this.value,
    required this.onChanged,
    super.key,
    this.minSegmentWidth = 92,
  });

  final List<AppSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final double minSegmentWidth;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : segments.length * minSegmentWidth;
        final neededWidth = segments.length * minSegmentWidth;
        final trackWidth = math.max(maxWidth, neededWidth);
        final control = SizedBox(
          width: trackWidth,
          child: _SegmentedTrack<T>(
            segments: segments,
            value: value,
            onChanged: onChanged,
          ),
        );

        if (neededWidth <= maxWidth) {
          return control;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: control,
        );
      },
    );
  }
}

class _SegmentedTrack<T> extends StatelessWidget {
  const _SegmentedTrack({
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final List<AppSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = math.max(
      0,
      segments.indexWhere((segment) => segment.value == value),
    );
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.all(4),
      backgroundColor: scheme.brightness == Brightness.dark
          ? scheme.surface.withValues(alpha: 0.86)
          : scheme.surface,
      child: SizedBox(
        height: 42,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / segments.length;
            return Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: AppMotion.normal,
                  curve: AppMotion.emphasizedCurve,
                  start: selectedIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(
                          alpha: scheme.brightness == Brightness.dark
                              ? 0.34
                              : 0.78,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final segment in segments)
                      Expanded(
                        child: _SegmentButton<T>(
                          segment: segment,
                          selected: segment.value == value,
                          onPressed: () => onChanged(segment.value),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.segment,
    required this.selected,
    required this.onPressed,
  });

  final AppSegment<T> segment;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.md),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (segment.icon != null) ...[
                    Icon(segment.icon, size: 16, color: color),
                    const SizedBox(width: AppSpacing.xs + 2),
                  ],
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: AppMotion.fast,
                      curve: AppMotion.standardCurve,
                      style:
                          theme.textTheme.labelMedium?.copyWith(
                            color: color,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w700,
                            letterSpacing: 0,
                          ) ??
                          TextStyle(
                            color: color,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                      child: Text(
                        segment.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
