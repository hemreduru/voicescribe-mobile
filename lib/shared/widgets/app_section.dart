import 'package:flutter/material.dart';

import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/widgets/app_card.dart';
import 'package:voicescribe_mobile/shared/widgets/app_segmented_control.dart';
import 'package:voicescribe_mobile/shared/widgets/premium_widgets.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
    this.trailing,
    this.showHeaderDivider = false,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final bool showHeaderDivider;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, subtitle: subtitle, trailing: trailing),
          if (children.isNotEmpty) ...[
            if (showHeaderDivider)
              const PremiumDivider()
            else
              const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ],
      ),
    );
  }
}

class AppLabeledControl extends StatelessWidget {
  const AppLabeledControl({
    required this.label,
    required this.child,
    super.key,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final inline = constraints.maxWidth >= AppLayout.compactWidth;
        final labelWidget = Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );

        if (!inline) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelWidget,
              const SizedBox(height: AppSpacing.sm),
              child,
            ],
          );
        }

        return Row(
          children: [
            SizedBox(width: 150, child: labelWidget),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class AppSegmentedField<T> extends StatelessWidget {
  const AppSegmentedField({
    required this.label,
    required this.value,
    required this.segments,
    required this.onChanged,
    super.key,
    this.minSegmentWidth = 92,
  });

  final String label;
  final T value;
  final List<AppSegment<T>> segments;
  final ValueChanged<T> onChanged;
  final double minSegmentWidth;

  @override
  Widget build(BuildContext context) {
    return AppLabeledControl(
      label: label,
      child: AppSegmentedControl<T>(
        value: value,
        segments: segments,
        minSegmentWidth: minSegmentWidth,
        onChanged: onChanged,
      ),
    );
  }
}

class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({required this.child, super.key, this.errorText});

  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (errorText != null) ...[
                Text(
                  errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
