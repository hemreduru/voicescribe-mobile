import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/widgets/app_button.dart';
import 'package:voicescribe_mobile/shared/widgets/app_card.dart';
import 'package:voicescribe_mobile/shared/widgets/app_page.dart';
import 'package:voicescribe_mobile/shared/widgets/premium_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loggingOut = false;
  String? _logoutError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final app = ref.watch(appControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SafeArea(
        bottom: false,
        child: AppPageListView(
          children: [
            AppCard(
              showAccent: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: l10n.account,
                    subtitle: l10n.authenticatedUser,
                  ),
                  const PremiumDivider(),
                  ActionRow(
                    icon: Icons.alternate_email,
                    title: app.currentUserEmail ?? '-',
                    subtitle: l10n.email,
                    trailing: const SizedBox.shrink(),
                  ),
                  if ((app.currentUserId ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ActionRow(
                      icon: Icons.badge_outlined,
                      title: app.currentUserId!,
                      subtitle: l10n.userId,
                      trailing: const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              showAccent: true,
              accentColor: theme.colorScheme.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: l10n.summarySettings,
                    subtitle: l10n.summaryPreferences,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.summaryProvider,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'local',
                        label: Text(l10n.local),
                        icon: const Icon(Icons.storage_outlined),
                      ),
                      ButtonSegment(
                        value: 'cloud',
                        label: Text(l10n.cloud),
                        icon: const Icon(Icons.cloud_outlined),
                      ),
                    ],
                    selected: {app.summaryProvider},
                    onSelectionChanged: (value) {
                      ref
                          .read(appControllerProvider)
                          .setSummaryProvider(value.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.summaryLength,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'short', label: Text(l10n.short)),
                      ButtonSegment(value: 'medium', label: Text(l10n.medium)),
                      ButtonSegment(value: 'long', label: Text(l10n.long)),
                    ],
                    selected: {app.summaryLength},
                    onSelectionChanged: (value) {
                      ref
                          .read(appControllerProvider)
                          .setSummaryLength(value.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              showAccent: true,
              accentColor: AppTheme.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: l10n.appearance, subtitle: l10n.theme),
                  const SizedBox(height: AppSpacing.lg),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.system),
                        icon: const Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.light),
                        icon: const Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.dark),
                        icon: const Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {app.themeMode},
                    onSelectionChanged: (value) {
                      ref.read(appControllerProvider).setThemeMode(value.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: l10n.preferences,
                    subtitle: l10n.comingSoon,
                  ),
                  const PremiumDivider(),
                  ActionRow(
                    icon: Icons.credit_card_outlined,
                    title: l10n.billingPlans,
                    subtitle: l10n.comingSoon,
                    trailing: StatusPill(
                      icon: Icons.schedule_outlined,
                      label: l10n.comingSoon,
                      compact: true,
                      color: AppTheme.amber,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ActionRow(
                    icon: Icons.notifications_none,
                    title: l10n.notifications,
                    subtitle: l10n.comingSoon,
                    trailing: StatusPill(
                      icon: Icons.schedule_outlined,
                      label: l10n.comingSoon,
                      compact: true,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
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
                if (_logoutError != null) ...[
                  Text(
                    _logoutError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppButton(
                  label: l10n.logout,
                  icon: Icons.logout,
                  onPressed: _handleLogout,
                  isLoading: _loggingOut,
                  expanded: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    setState(() {
      _loggingOut = true;
      _logoutError = null;
    });

    try {
      await ref.read(appControllerProvider).logout();
    } catch (error) {
      if (mounted) {
        setState(() {
          _logoutError = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loggingOut = false;
        });
      }
    }
  }
}
