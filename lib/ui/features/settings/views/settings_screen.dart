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
import 'package:voicescribe_mobile/ui/features/settings/bloc/settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) =>
          previous.preferences != current.preferences ||
          previous.session != current.session ||
          previous.loggingOut != current.loggingOut ||
          previous.syncing != current.syncing ||
          previous.lastSyncAt != current.lastSyncAt ||
          previous.syncErrorMessage != current.syncErrorMessage ||
          previous.errorMessage != current.errorMessage ||
          previous.pendingSyncCount != current.pendingSyncCount,
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
                      onPressed: () => _confirmLogout(context),
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
                  title: l10n.transcriptionSettings,
                  subtitle: l10n.transcriptionSettingsSubtitle,
                  children: [
                    AppSegmentedField<String>(
                      label: l10n.transcriptionLanguage,
                      value: preferences.transcriptionLanguage,
                      segments: [
                        AppSegment(value: 'tr', label: l10n.turkish),
                        AppSegment(value: 'en', label: l10n.english),
                      ],
                      onChanged: (value) => context.read<SettingsBloc>().add(
                        SettingsTranscriptionLanguageChanged(value),
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
                                  : AppTheme.positive,
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
                                  if (state.pendingSyncCount > 0) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      l10n.unsyncedCount(
                                        state.pendingSyncCount,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.logoutConfirmTitle),
          content: Text(l10n.logoutConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.logout),
            ),
          ],
        );
      },
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<SettingsBloc>().add(const SettingsLogoutRequested());
    }
  }
}
