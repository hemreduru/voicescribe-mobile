import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/utils/text_utils.dart';
import 'package:voicescribe_mobile/shared/widgets/app_button.dart';
import 'package:voicescribe_mobile/shared/widgets/app_card.dart';
import 'package:voicescribe_mobile/shared/widgets/app_page.dart';
import 'package:voicescribe_mobile/shared/widgets/premium_widgets.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final app = ref.watch(appControllerProvider);
    final latestTranscript = app.transcripts.isEmpty
        ? null
        : app.transcripts.first;
    final latestText = latestTranscript == null
        ? ''
        : app.transcriptText(latestTranscript.id);
    final latestChunks = latestTranscript == null
        ? 0
        : app.chunksFor(latestTranscript.id).length;
    final latestSummary = latestTranscript == null
        ? null
        : app.latestSummaryFor(latestTranscript.id);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.summary),
        actions: [
          IconButton(
            onPressed: _openSummarySettings,
            icon: const Icon(Icons.tune),
            tooltip: l10n.summarySettings,
          ),
        ],
      ),
      body: SafeArea(
        child: AppPageListView(
          children: [
            AppCard(
              showAccent: true,
              accentColor: latestText.isEmpty ? AppTheme.amber : AppTheme.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: l10n.latestTranscript,
                    subtitle: latestTranscript == null
                        ? l10n.noTranscriptAvailable
                        : DateFormat('d MMMM HH:mm').format(
                            latestTranscript.recordedAt ??
                                latestTranscript.createdAt,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ActionChip(
                        avatar: Icon(_providerIcon(), size: 17),
                        label: Text('${_providerLabel()} • ${_lengthLabel()}'),
                        onPressed: _openSummarySettings,
                      ),
                      if (latestText.isNotEmpty)
                        StatusPill(
                          icon: Icons.check_circle,
                          label: l10n.readyToSummarize,
                          color: AppTheme.teal,
                        ),
                      if (latestTranscript != null)
                        MetricPill(
                          icon: Icons.timer_outlined,
                          value: formatCompactDuration(
                            latestTranscript.durationSeconds,
                          ),
                          label: l10n.duration,
                        ),
                      if (latestTranscript != null)
                        MetricPill(
                          icon: Icons.graphic_eq,
                          value: '$latestChunks',
                          label: l10n.chunks,
                          color: AppTheme.amber,
                        ),
                    ],
                  ),
                  const PremiumDivider(),
                  Text(
                    latestTranscript?.title ?? l10n.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    latestText.isEmpty ? l10n.summaryPlaceholder : latestText,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l10n.generateSummary,
              icon: Icons.auto_awesome,
              onPressed: latestText.isEmpty ? null : _simulateSummary,
              isLoading: app.summaryGenerating,
              expanded: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              showAccent: true,
              accentColor: theme.colorScheme.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    icon: Icons.auto_awesome,
                    label: latestSummary == null
                        ? l10n.noSummaryYet
                        : l10n.summaryGeneratedAt(
                            DateFormat(
                              'd MMM HH:mm',
                            ).format(latestSummary.createdAt),
                          ),
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    latestSummary?.summaryText ?? l10n.summaryPlaceholder,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulateSummary() async {
    final app = ref.read(appControllerProvider);
    await app.generateSummaryForLatest();
  }

  void _openSummarySettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l10n = context.l10n;
        final app = ref.read(appControllerProvider);
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              child: AppModalBody(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.summarySettings,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.settings,
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
                          icon: const Icon(Icons.storage),
                        ),
                        ButtonSegment(
                          value: 'cloud',
                          label: Text(l10n.cloud),
                          icon: const Icon(Icons.cloud),
                        ),
                      ],
                      selected: {app.summaryProvider},
                      onSelectionChanged: (value) {
                        app.setSummaryProvider(value.first);
                        modalSetState(() {});
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.duration,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'short', label: Text(l10n.short)),
                        ButtonSegment(
                          value: 'medium',
                          label: Text(l10n.medium),
                        ),
                        ButtonSegment(value: 'long', label: Text(l10n.long)),
                      ],
                      selected: {app.summaryLength},
                      onSelectionChanged: (value) {
                        app.setSummaryLength(value.first);
                        modalSetState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _providerLabel() {
    final l10n = context.l10n;
    return switch (ref.read(appControllerProvider).summaryProvider) {
      'cloud' => l10n.cloud,
      _ => l10n.local,
    };
  }

  String _lengthLabel() {
    final l10n = context.l10n;
    return switch (ref.read(appControllerProvider).summaryLength) {
      'short' => l10n.short,
      'long' => l10n.long,
      _ => l10n.medium,
    };
  }

  IconData _providerIcon() {
    return switch (ref.read(appControllerProvider).summaryProvider) {
      'cloud' => Icons.cloud,
      _ => Icons.storage,
    };
  }
}
