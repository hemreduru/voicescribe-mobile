import 'package:flutter/material.dart';

import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/widgets/app_button.dart';
import 'package:voicescribe_mobile/shared/widgets/app_text_field.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null)
          trailing!
        else if (actionLabel != null && onAction != null)
          AppButton(
            label: actionLabel!,
            icon: actionIcon ?? Icons.arrow_forward,
            onPressed: onAction,
            variant: AppButtonVariant.text,
          ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.icon,
    super.key,
    this.color,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md : AppSpacing.md + 2,
        vertical: compact ? AppSpacing.sm : AppSpacing.sm + 1,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 15 : 16, color: accent),
          const SizedBox(width: AppSpacing.sm - 2),
          Text(
            label,
            style:
                (compact
                        ? theme.textTheme.labelLarge
                        : theme.textTheme.labelMedium)
                    ?.copyWith(color: accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class AppEditableTitle extends StatefulWidget {
  const AppEditableTitle({
    required this.title,
    required this.placeholder,
    required this.onSubmitted,
    required this.editTooltip,
    super.key,
  });

  final String? title;
  final String placeholder;
  final ValueChanged<String> onSubmitted;
  final String editTooltip;

  @override
  State<AppEditableTitle> createState() => _AppEditableTitleState();
}

class _AppEditableTitleState extends State<AppEditableTitle> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _editing = false;

  String get _effectiveTitle {
    final title = widget.title?.trim();
    return title == null || title.isEmpty ? widget.placeholder : title;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title ?? '');
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppEditableTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.title != widget.title) {
      _controller.text = widget.title ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_editing) {
      return AppTextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        hintText: widget.placeholder,
        prefixIcon: Icons.edit_outlined,
        textInputAction: TextInputAction.done,
        onSubmitted: _submit,
        semanticLabel: widget.editTooltip,
      );
    }

    return Semantics(
      button: true,
      label: widget.editTooltip,
      child: InkWell(
        onTap: _startEditing,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _effectiveTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.72,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _controller.text = widget.title ?? '';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  void _submit(String value) {
    if (!_editing) {
      return;
    }

    final next = value.trim();
    final previous = widget.title?.trim() ?? '';
    setState(() => _editing = false);
    if (next != previous) {
      widget.onSubmitted(next);
    }
  }

  void _handleFocusChange() {
    if (_editing && !_focusNode.hasFocus) {
      _submit(_controller.text);
    }
  }
}

class MetricPill extends StatelessWidget {
  const MetricPill({
    required this.label,
    required this.value,
    super.key,
    this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.92),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: AppSpacing.sm - 2),
          ],
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm - 3),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PremiumDivider extends StatelessWidget {
  const PremiumDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: AppSpacing.xl,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.86),
    );
  }
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    required this.icon,
    super.key,
    this.color,
    this.size = 38,
    this.iconSize = 19,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Icon(icon, size: iconSize, color: accent),
    );
  }
}

class AppDurationDisplay extends StatelessWidget {
  const AppDurationDisplay({
    required this.value,
    super.key,
    this.icon = Icons.timer_outlined,
  });

  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class AppErrorText extends StatelessWidget {
  const AppErrorText({
    required this.message,
    super.key,
    this.textAlign = TextAlign.start,
  });

  final String message;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      message,
      textAlign: textAlign,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }
}

class AppSelectionBar extends StatelessWidget {
  const AppSelectionBar({
    required this.label,
    required this.action,
    super.key,
    this.icon = Icons.check_circle,
  });

  final String label;
  final Widget action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatusPill(icon: icon, label: label),
        ),
        const SizedBox(width: AppSpacing.md),
        action,
      ],
    );
  }
}

class ActionRow extends StatelessWidget {
  const ActionRow({
    required this.icon,
    required this.title,
    super.key,
    this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          AppIconBadge(icon: icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          trailing ??
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: content,
    );
  }
}
