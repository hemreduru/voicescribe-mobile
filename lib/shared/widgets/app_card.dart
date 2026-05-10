import 'package:flutter/material.dart';

import 'package:voicescribe_mobile/shared/theme/app_theme.dart';

class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.backgroundColor,
    this.selected = false,
    this.accentColor,
    this.showAccent = false,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool selected;
  final Color? accentColor;
  final bool showAccent;
  final String? semanticLabel;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = widget.accentColor ?? scheme.primary;
    final active = widget.selected || _pressed;
    final radius = BorderRadius.circular(AppRadii.lg);

    final surface =
        widget.backgroundColor ??
        Color.alphaBlend(
          (active ? accent : scheme.primary).withValues(
            alpha: active ? 0.08 : 0.02,
          ),
          scheme.surface,
        );

    final content = Stack(
      children: [
        if (widget.showAccent)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standardCurve,
                width: active ? 4 : 3,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
          ),
        Padding(padding: widget.padding, child: widget.child),
      ],
    );

    final card = AnimatedScale(
      duration: AppMotion.fast,
      curve: AppMotion.standardCurve,
      scale: _pressed ? 0.992 : 1,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.standardCurve,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: radius,
          border: Border.all(
            color: active
                ? accent.withValues(alpha: 0.78)
                : scheme.outlineVariant.withValues(alpha: 0.95),
            width: active ? 1.35 : 1,
          ),
          boxShadow: active
              ? AppElevation.soft(accent)
              : AppElevation.soft(scheme.shadow),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: widget.onTap == null
              ? content
              : InkWell(
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
        showAccent: true,
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
