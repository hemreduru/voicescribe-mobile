import 'package:flutter/material.dart';

import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';

class AppSurface extends StatefulWidget {
  const AppSurface({
    required this.child,
    super.key,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.backgroundColor,
    this.selected = false,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool selected;
  final String? semanticLabel;

  @override
  State<AppSurface> createState() => _AppSurfaceState();
}

class _AppSurfaceState extends State<AppSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.primary;
    final active = widget.selected || _pressed;
    final radius = BorderRadius.circular(AppRadii.lg);

    final surface =
        widget.backgroundColor ??
        Color.alphaBlend(
          active
              ? accent.withValues(
                  alpha: scheme.brightness == Brightness.dark ? 0.09 : 0.05,
                )
              : Colors.white.withValues(
                  alpha: scheme.brightness == Brightness.dark ? 0.03 : 0,
                ),
          scheme.surface,
        );

    final borderColor = active
        ? accent.withValues(
            alpha: scheme.brightness == Brightness.dark ? 0.52 : 0.38,
          )
        : scheme.outlineVariant.withValues(
            alpha: scheme.brightness == Brightness.dark ? 0.70 : 0.92,
          );

    final content = Padding(padding: widget.padding, child: widget.child);

    final card = AnimatedScale(
      duration: AppMotion.instant,
      curve: AppMotion.standardCurve,
      scale: _pressed ? 0.996 : 1,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standardCurve,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: radius,
          border: Border.all(color: borderColor),
          boxShadow: AppElevation.card(active ? accent : scheme.shadow),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: widget.onTap == null
              ? content
              : MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: widget.onTap,
                    onHighlightChanged: (value) {
                      if (mounted) {
                        setState(() => _pressed = value);
                      }
                    },
                    borderRadius: radius,
                    splashColor: accent.withValues(alpha: 0.10),
                    highlightColor: accent.withValues(alpha: 0.06),
                    child: content,
                  ),
                ),
        ),
      ),
    );

    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap == null ? null : true,
      selected: widget.selected ? true : null,
      label: widget.semanticLabel,
      container: widget.semanticLabel != null || widget.onTap != null,
      child: card,
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.selected = false,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: padding,
      onTap: onTap,
      selected: selected,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
