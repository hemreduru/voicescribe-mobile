import 'package:flutter/material.dart';

import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_card.dart';

class AppNavigationDestination {
  const AppNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final List<AppNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.all(5),
      backgroundColor: scheme.brightness == Brightness.dark
          ? scheme.surface.withValues(alpha: 0.94)
          : scheme.surface.withValues(alpha: 0.98),
      child: SizedBox(
        height: 66,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / destinations.length;
            return Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: AppMotion.slow,
                  curve: AppMotion.emphasizedCurve,
                  start: selectedIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(
                          alpha: scheme.brightness == Brightness.dark
                              ? 0.36
                              : 0.76,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var index = 0; index < destinations.length; index++)
                      Expanded(
                        child: _NavigationItem(
                          destination: destinations[index],
                          selected: index == selectedIndex,
                          onTap: () => onDestinationSelected(index),
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

class AppSideNavigationRail extends StatelessWidget {
  const AppSideNavigationRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
    this.extended = false,
  });

  final List<AppNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = extended ? 216.0 : 76.0;
    const itemHeight = 58.0;

    return SizedBox(
      width: width,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
          ),
          child: AppSurface(
            padding: const EdgeInsets.all(5),
            backgroundColor: scheme.brightness == Brightness.dark
                ? scheme.surface.withValues(alpha: 0.92)
                : scheme.surface.withValues(alpha: 0.98),
            child: SizedBox(
              height: destinations.length * itemHeight,
              child: Stack(
                children: [
                  AnimatedPositionedDirectional(
                    duration: AppMotion.slow,
                    curve: AppMotion.emphasizedCurve,
                    start: 0,
                    end: 0,
                    top: selectedIndex * itemHeight,
                    height: itemHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(
                          alpha: scheme.brightness == Brightness.dark
                              ? 0.36
                              : 0.76,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      for (var index = 0; index < destinations.length; index++)
                        SizedBox(
                          height: itemHeight,
                          child: _NavigationItem(
                            destination: destinations[index],
                            selected: index == selectedIndex,
                            extended: extended,
                            onTap: () => onDestinationSelected(index),
                          ),
                        ),
                    ],
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

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.extended = false,
  });

  final AppNavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final icon = selected ? destination.selectedIcon : destination.icon;

    final content = extended
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: selected ? 23 : 22),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: _NavigationLabel(
                  label: destination.label,
                  color: color,
                  selected: selected,
                ),
              ),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: selected ? 23 : 22),
              const SizedBox(height: AppSpacing.xs),
              _NavigationLabel(
                label: destination.label,
                color: color,
                selected: selected,
              ),
            ],
          );

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _NavigationLabel extends StatelessWidget {
  const _NavigationLabel({
    required this.label,
    required this.color,
    required this.selected,
  });

  final String label;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedDefaultTextStyle(
      duration: AppMotion.fast,
      curve: AppMotion.standardCurve,
      style:
          theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0,
          ) ??
          TextStyle(
            color: color,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
