import 'package:flutter/material.dart';

class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor,
    this.selected = false,
    this.accentColor,
    this.showAccent = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool selected;
  final Color? accentColor;
  final bool showAccent;

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
    final surface =
        widget.backgroundColor ??
        (widget.selected
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.08),
                scheme.surfaceContainerLow,
              )
            : scheme.surfaceContainerLow);
    final radius = BorderRadius.circular(8);

    final content = Stack(
      children: [
        if (widget.showAccent)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: active ? 5 : 3,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        Padding(padding: widget.padding, child: widget.child),
      ],
    );

    final card = AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      scale: _pressed ? 0.985 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: radius,
          border: Border.all(
            color: active
                ? accent
                : scheme.outlineVariant.withValues(alpha: 0.72),
            width: active ? 1.35 : 1,
          ),
          boxShadow: [
            if (_pressed || widget.selected)
              BoxShadow(
                color: accent.withValues(alpha: _pressed ? 0.14 : 0.08),
                blurRadius: _pressed ? 18 : 14,
                offset: const Offset(0, 8),
              ),
          ],
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
                  splashColor: accent.withValues(alpha: 0.08),
                  highlightColor: accent.withValues(alpha: 0.05),
                  child: content,
                ),
        ),
      ),
    );

    return card;
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
            Icon(icon, size: 44, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
