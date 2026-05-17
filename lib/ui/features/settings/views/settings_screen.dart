import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_button.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_page.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_section.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_segmented_control.dart';
import 'package:voicescribe_mobile/ui/core/widgets/premium_widgets.dart';
import 'package:voicescribe_mobile/ui/features/bootstrap/bloc/bootstrap_bloc.dart';
import 'package:voicescribe_mobile/ui/features/settings/bloc/settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bootstrapState = context.watch<BootstrapBloc>().state;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final session = state.session;
        final preferences = state.preferences;
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
                      title: session?.email ?? '-',
                      subtitle: l10n.email,
                      trailing: const SizedBox.shrink(),
                    ),
                    if ((session?.userId ?? '').isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ActionRow(
                        icon: Icons.badge_outlined,
                        title: session!.userId,
                        subtitle: l10n.userId,
                        trailing: const SizedBox.shrink(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: l10n.logout,
                      icon: Icons.logout,
                      onPressed: () => context.read<SettingsBloc>().add(
                        const SettingsLogoutRequested(),
                      ),
                      isLoading: state.loggingOut,
                      expanded: true,
                      variant: AppButtonVariant.outline,
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppErrorText(message: state.errorMessage!),
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
                      value: preferences.summaryProvider,
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
                      onChanged: (value) => context.read<SettingsBloc>().add(
                        SettingsSummaryProviderChanged(value),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSegmentedField<String>(
                      label: l10n.summaryLength,
                      value: preferences.summaryLength,
                      segments: [
                        AppSegment(value: 'short', label: l10n.short),
                        AppSegment(value: 'medium', label: l10n.medium),
                        AppSegment(value: 'long', label: l10n.long),
                      ],
                      onChanged: (value) => context.read<SettingsBloc>().add(
                        SettingsSummaryLengthChanged(value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionCard(
                  title: l10n.appearance,
                  subtitle: l10n.theme,
                  children: [
                    AppSegmentedField<String>(
                      label: l10n.theme,
                      value: preferences.themeMode,
                      minSegmentWidth: 104,
                      segments: [
                        AppSegment(
                          value: 'system',
                          label: l10n.system,
                          icon: Icons.brightness_auto,
                        ),
                        AppSegment(
                          value: 'light',
                          label: l10n.light,
                          icon: Icons.light_mode_outlined,
                        ),
                        AppSegment(
                          value: 'dark',
                          label: l10n.dark,
                          icon: Icons.dark_mode_outlined,
                        ),
                      ],
                      onChanged: (value) => context.read<SettingsBloc>().add(
                        SettingsThemeModeChanged(value),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSegmentedField<String>(
                      label: l10n.language,
                      value: preferences.localePreference,
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
                      onChanged: (value) => context.read<SettingsBloc>().add(
                        SettingsLocalePreferenceChanged(value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionCard(
                  title: l10n.sync,
                  subtitle: l10n.syncSectionSubtitle,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppIconBadge(
                              icon: state.syncing
                                  ? Icons.sync
                                  : Icons.cloud_done_outlined,
                              color: state.syncing
                                  ? Theme.of(context).colorScheme.secondary
                                  : AppTheme.teal,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.syncing
                                        ? l10n.syncInProgress
                                        : l10n.syncIdle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    state.lastSyncAt == null
                                        ? l10n.lastSyncNever
                                        : l10n.lastSyncAt(
                                            DateFormat(
                                              'dd MMM, HH:mm',
                                              Localizations.localeOf(
                                                context,
                                              ).toLanguageTag(),
                                            ).format(state.lastSyncAt!),
                                          ),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: l10n.syncNow,
                          icon: Icons.sync,
                          onPressed: state.syncing
                              ? null
                              : () => context.read<SettingsBloc>().add(
                                  const SettingsManualSyncRequested(),
                                ),
                          isLoading: state.syncing,
                          variant: AppButtonVariant.outline,
                          expanded: true,
                        ),
                        if (state.syncErrorMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppErrorText(message: state.syncErrorMessage!),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionCard(
                  title: l10n.systemStatus,
                  children: [
                    ActionRow(
                      icon: _modelStatusIcon(bootstrapState.modelState),
                      title: _modelStatusLabel(
                        context,
                        bootstrapState.modelState,
                      ),
                      trailing:
                          bootstrapState.modelState ==
                              ModelBootstrapState.failed
                          ? AppButton(
                              label: l10n.retrySetup,
                              icon: Icons.refresh,
                              onPressed: () => context
                                  .read<BootstrapBloc>()
                                  .add(const BootstrapRetried()),
                              variant: AppButtonVariant.outline,
                            )
                          : StatusPill(
                              icon: _modelStatusIcon(bootstrapState.modelState),
                              label: _modelStatusLabel(
                                context,
                                bootstrapState.modelState,
                              ),
                              compact: true,
                              color: _modelStatusColor(
                                context,
                                bootstrapState.modelState,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
}
