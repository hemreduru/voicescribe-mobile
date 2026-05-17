import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/utils/model_download_formatters.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_button.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_page.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_section.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_segmented_control.dart';
import 'package:voicescribe_mobile/ui/core/widgets/premium_widgets.dart';
import 'package:voicescribe_mobile/ui/features/bootstrap/bloc/bootstrap_bloc.dart';
import 'package:voicescribe_mobile/ui/features/settings/bloc/settings_bloc.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

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
                  title: l10n.transcriptionModelSettings,
                  subtitle: l10n.transcriptionModelPreferences,
                  children: [
                    _ModelRecommendationBanner(
                      profile: state.deviceProfile,
                      tierLabel: state.deviceProfile == null
                          ? null
                          : _tierLabel(context, state.deviceProfile!.tier),
                      subtitle: state.deviceProfile == null
                          ? null
                          : _deviceSpecsSubtitle(state.deviceProfile!),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (state.modelCatalogLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state.modelCatalogErrorMessage != null)
                      AppErrorText(message: state.modelCatalogErrorMessage!)
                    else
                      ...state.modelCatalog.map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _TranscriptionModelTile(
                            option: option,
                            displayName: _modelDisplayName(option.model),
                            description: _modelDescription(
                              context,
                              option.model,
                            ),
                            selectedModelKey: preferences.transcriptionModel,
                            isBusy:
                                state.applyingTranscriptionModel ||
                                bootstrapState.modelState ==
                                    ModelBootstrapState.bootstrapping,
                            activeDownload:
                                bootstrapState.modelState ==
                                    ModelBootstrapState.bootstrapping &&
                                bootstrapState.selectedModelKey ==
                                    modelKeyFromWhisperModel(option.model),
                            downloadProgress: bootstrapState.downloadProgress,
                            compatibilityLabel: _modelCompatibilityLabel(
                              context,
                              option.compatibility,
                            ),
                            downloadSizeLabel: _modelDownloadLabel(
                              context,
                              option,
                            ),
                            recommendedLabel: l10n.recommendedForYourDevice,
                            onSelected: () {
                              final key = modelKeyFromWhisperModel(
                                option.model,
                              );
                              if (key == preferences.transcriptionModel) {
                                return;
                              }
                              context.read<SettingsBloc>().add(
                                SettingsTranscriptionModelChanged(key),
                              );
                              context.read<BootstrapBloc>().add(
                                BootstrapTranscriptionModelChanged(key),
                              );
                            },
                          ),
                        ),
                      ),
                    if (state.applyingTranscriptionModel) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.modelApplyingSelection,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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

  String _tierLabel(BuildContext context, DevicePerformanceTier tier) {
    final l10n = context.l10n;
    return switch (tier) {
      DevicePerformanceTier.entry => l10n.deviceTierEntry,
      DevicePerformanceTier.balanced => l10n.deviceTierBalanced,
      DevicePerformanceTier.performance => l10n.deviceTierPerformance,
      DevicePerformanceTier.premium => l10n.deviceTierPremium,
    };
  }

  String _deviceSpecsSubtitle(DevicePerformanceProfile profile) {
    final memoryText = profile.memoryBytes == null
        ? null
        : formatModelDownloadBytes(profile.memoryBytes!);
    if (memoryText == null) {
      return '${profile.cpuCores} CPU';
    }
    return '${profile.cpuCores} CPU • $memoryText RAM';
  }

  String _modelCompatibilityLabel(
    BuildContext context,
    TranscriptionModelCompatibility compatibility,
  ) {
    final l10n = context.l10n;
    return switch (compatibility) {
      TranscriptionModelCompatibility.recommended =>
        l10n.modelCompatibilityRecommended,
      TranscriptionModelCompatibility.supported =>
        l10n.modelCompatibilitySupported,
      TranscriptionModelCompatibility.limited => l10n.modelCompatibilityLimited,
    };
  }

  String _modelDisplayName(WhisperModel model) {
    return switch (model) {
      WhisperModel.tiny => 'Tiny',
      WhisperModel.base => 'Base',
      WhisperModel.small => 'Small',
      WhisperModel.medium => 'Medium',
      WhisperModel.large => 'Large v3',
      WhisperModel.largeV3Turbo => 'Large v3 Turbo',
      WhisperModel.tinyEn => 'Tiny',
      WhisperModel.baseEn => 'Base',
      WhisperModel.smallEn => 'Small',
      WhisperModel.mediumEn => 'Medium',
    };
  }

  String _modelDescription(BuildContext context, WhisperModel model) {
    final l10n = context.l10n;
    return switch (model) {
      WhisperModel.tiny => l10n.modelTinyDescription,
      WhisperModel.base => l10n.modelBaseDescription,
      WhisperModel.small => l10n.modelSmallDescription,
      WhisperModel.medium => l10n.modelMediumDescription,
      WhisperModel.large => l10n.modelLargeV3Description,
      WhisperModel.largeV3Turbo => l10n.modelLargeV3TurboDescription,
      WhisperModel.tinyEn => l10n.modelTinyDescription,
      WhisperModel.baseEn => l10n.modelBaseDescription,
      WhisperModel.smallEn => l10n.modelSmallDescription,
      WhisperModel.mediumEn => l10n.modelMediumDescription,
    };
  }

  String _modelDownloadLabel(
    BuildContext context,
    TranscriptionModelCatalogEntry option,
  ) {
    final l10n = context.l10n;
    if (option.isDownloaded) {
      return l10n.modelAlreadyDownloaded;
    }
    final remaining = option.remainingBytes;
    if (remaining == null) {
      return l10n.modelDownloadSizeUnknown;
    }
    return l10n.modelDownloadRemaining(formatModelDownloadBytes(remaining));
  }
}

class _ModelRecommendationBanner extends StatelessWidget {
  const _ModelRecommendationBanner({
    required this.profile,
    required this.tierLabel,
    required this.subtitle,
  });

  final DevicePerformanceProfile? profile;
  final String? tierLabel;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    if (profile == null || tierLabel == null) {
      return Text(
        l10n.modelLoading,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recommendedForYourDevice,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.deviceProfileLabel(tierLabel!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer.withValues(
                  alpha: 0.85,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TranscriptionModelTile extends StatelessWidget {
  const _TranscriptionModelTile({
    required this.option,
    required this.displayName,
    required this.description,
    required this.selectedModelKey,
    required this.isBusy,
    required this.activeDownload,
    required this.downloadProgress,
    required this.compatibilityLabel,
    required this.downloadSizeLabel,
    required this.recommendedLabel,
    required this.onSelected,
  });

  final TranscriptionModelCatalogEntry option;
  final String displayName;
  final String description;
  final String selectedModelKey;
  final bool isBusy;
  final bool activeDownload;
  final ModelDownloadProgress? downloadProgress;
  final String compatibilityLabel;
  final String downloadSizeLabel;
  final String recommendedLabel;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modelKey = modelKeyFromWhisperModel(option.model);
    final isSelected = selectedModelKey == modelKey;
    final compatibilityColor = switch (option.compatibility) {
      TranscriptionModelCompatibility.recommended => AppTheme.teal,
      TranscriptionModelCompatibility.supported =>
        theme.colorScheme.onSurfaceVariant,
      TranscriptionModelCompatibility.limited => theme.colorScheme.error,
    };

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.md),
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
            : theme.colorScheme.surface,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.85),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _InfoChip(label: compatibilityLabel, color: compatibilityColor),
              _InfoChip(
                label: downloadSizeLabel,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              if (option.isRecommended)
                _InfoChip(
                  label: recommendedLabel,
                  color: theme.colorScheme.secondary,
                ),
            ],
          ),
          if (activeDownload && downloadProgress != null) ...[
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: downloadProgress!.percent == null
                  ? null
                  : downloadProgress!.percent! / 100,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _progressLabel(context, downloadProgress!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );

    if (isBusy) {
      return content;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: displayName,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: content,
      ),
    );
  }

  String _progressLabel(BuildContext context, ModelDownloadProgress progress) {
    return formatModelDownloadProgress(context.l10n, progress);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
