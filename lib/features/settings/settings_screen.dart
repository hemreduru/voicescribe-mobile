import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/widgets/app_button.dart';
import 'package:voicescribe_mobile/shared/widgets/app_page.dart';
import 'package:voicescribe_mobile/shared/widgets/app_section.dart';
import 'package:voicescribe_mobile/shared/widgets/app_segmented_control.dart';
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
            AppSectionCard(
              title: l10n.account,
              subtitle: l10n.authenticatedUser,
              showHeaderDivider: true,
              children: [
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
            const SizedBox(height: AppSpacing.lg),
            AppSectionCard(
              title: l10n.summarySettings,
              subtitle: l10n.summaryPreferences,
              children: [
                AppSegmentedField<String>(
                  label: l10n.summaryProvider,
                  value: app.summaryProvider,
                  segments: [
                    AppSegment(
                      value: 'local',
                      label: l10n.local,
                      icon: Icons.storage_outlined,
                    ),
                    AppSegment(
                      value: 'cloud',
                      label: l10n.cloud,
                      icon: Icons.cloud_outlined,
                    ),
                  ],
                  onChanged: (value) {
                    ref.read(appControllerProvider).setSummaryProvider(value);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSegmentedField<String>(
                  label: l10n.summaryLength,
                  value: app.summaryLength,
                  segments: [
                    AppSegment(value: 'short', label: l10n.short),
                    AppSegment(value: 'medium', label: l10n.medium),
                    AppSegment(value: 'long', label: l10n.long),
                  ],
                  onChanged: (value) {
                    ref.read(appControllerProvider).setSummaryLength(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSectionCard(
              title: l10n.appearance,
              subtitle: l10n.theme,
              children: [
                AppSegmentedField<ThemeMode>(
                  label: l10n.theme,
                  value: app.themeMode,
                  minSegmentWidth: 104,
                  segments: [
                    AppSegment(
                      value: ThemeMode.system,
                      label: l10n.system,
                      icon: Icons.brightness_auto,
                    ),
                    AppSegment(
                      value: ThemeMode.light,
                      label: l10n.light,
                      icon: Icons.light_mode_outlined,
                    ),
                    AppSegment(
                      value: ThemeMode.dark,
                      label: l10n.dark,
                      icon: Icons.dark_mode_outlined,
                    ),
                  ],
                  onChanged: (value) {
                    ref.read(appControllerProvider).setThemeMode(value);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSegmentedField<String>(
                  label: l10n.language,
                  value: app.localePreference,
                  minSegmentWidth: 104,
                  segments: [
                    AppSegment(
                      value: 'system',
                      label: l10n.system,
                      icon: Icons.language,
                    ),
                    AppSegment(value: 'en', label: l10n.english),
                    AppSegment(value: 'tr', label: l10n.turkish),
                  ],
                  onChanged: (value) {
                    ref.read(appControllerProvider).setLocalePreference(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSectionCard(
              title: l10n.systemStatus,
              children: [
                ActionRow(
                  icon: _modelStatusIcon(app.modelState),
                  title: _modelStatusLabel(context, app.modelState),
                  trailing: app.modelState == ModelBootstrapState.failed
                      ? AppButton(
                          label: l10n.retrySetup,
                          icon: Icons.refresh,
                          onPressed: app.bootstrap,
                          variant: AppButtonVariant.outline,
                        )
                      : StatusPill(
                          icon: _modelStatusIcon(app.modelState),
                          label: _modelStatusLabel(context, app.modelState),
                          compact: true,
                          color: _modelStatusColor(context, app.modelState),
                        ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSectionCard(
              title: l10n.preferences,
              subtitle: l10n.comingSoon,
              showHeaderDivider: true,
              children: [
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
          ],
        ),
      ),
      bottomNavigationBar: AppBottomActionBar(
        errorText: _logoutError,
        child: AppButton(
          label: l10n.logout,
          icon: Icons.logout,
          onPressed: _handleLogout,
          isLoading: _loggingOut,
          expanded: true,
        ),
      ),
    );
  }

  String _modelStatusLabel(
    BuildContext context,
    ModelBootstrapState modelState,
  ) {
    final l10n = context.l10n;
    return switch (modelState) {
      ModelBootstrapState.ready => l10n.modelReady,
      ModelBootstrapState.failed => l10n.bootstrapFailed,
      ModelBootstrapState.bootstrapping => l10n.modelLoading,
    };
  }

  IconData _modelStatusIcon(ModelBootstrapState modelState) {
    return switch (modelState) {
      ModelBootstrapState.ready => Icons.check_circle,
      ModelBootstrapState.failed => Icons.error_outline,
      ModelBootstrapState.bootstrapping => Icons.sync,
    };
  }

  Color _modelStatusColor(
    BuildContext context,
    ModelBootstrapState modelState,
  ) {
    return switch (modelState) {
      ModelBootstrapState.ready => AppTheme.teal,
      ModelBootstrapState.failed => Theme.of(context).colorScheme.error,
      ModelBootstrapState.bootstrapping => Theme.of(
        context,
      ).colorScheme.secondary,
    };
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
