import 'package:flutter/material.dart';

import 'package:voicescribe_mobile/shared/theme/app_theme.dart';

enum AppButtonVariant { primary, tonal, outline, text }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    super.key,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expanded = false,
    this.semanticLabel,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expanded;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final button = _buildButton(effectiveOnPressed);
    final sizedButton = expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;

    return Semantics(
      button: true,
      enabled: effectiveOnPressed != null,
      label: semanticLabel ?? label,
      child: sizedButton,
    );
  }

  Widget _buildButton(VoidCallback? effectiveOnPressed) {
    final leading = isLoading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon == null
        ? null
        : Icon(icon);

    return switch (variant) {
      AppButtonVariant.primary =>
        leading == null
            ? FilledButton(onPressed: effectiveOnPressed, child: Text(label))
            : FilledButton.icon(
                onPressed: effectiveOnPressed,
                icon: leading,
                label: Text(label),
              ),
      AppButtonVariant.tonal =>
        leading == null
            ? FilledButton.tonal(
                onPressed: effectiveOnPressed,
                child: Text(label),
              )
            : FilledButton.tonalIcon(
                onPressed: effectiveOnPressed,
                icon: leading,
                label: Text(label),
              ),
      AppButtonVariant.outline =>
        leading == null
            ? OutlinedButton(onPressed: effectiveOnPressed, child: Text(label))
            : OutlinedButton.icon(
                onPressed: effectiveOnPressed,
                icon: leading,
                label: Text(label),
              ),
      AppButtonVariant.text =>
        leading == null
            ? TextButton(onPressed: effectiveOnPressed, child: Text(label))
            : TextButton.icon(
                onPressed: effectiveOnPressed,
                icon: leading,
                label: Text(label),
              ),
    };
  }
}

class AppButtonGroup extends StatelessWidget {
  const AppButtonGroup({
    required this.children,
    super.key,
    this.alignment = WrapAlignment.center,
  });

  final List<Widget> children;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: children,
    );
  }
}
