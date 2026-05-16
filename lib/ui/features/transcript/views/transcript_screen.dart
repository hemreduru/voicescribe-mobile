import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/domain/utils/text_utils.dart';
import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_button.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_card.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_page.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_segmented_control.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_text_field.dart';
import 'package:voicescribe_mobile/ui/core/widgets/premium_widgets.dart';
import 'package:voicescribe_mobile/ui/features/transcript/bloc/transcript_detail_bloc.dart';
import 'package:voicescribe_mobile/ui/features/transcript/bloc/transcript_list_bloc.dart';

class TranscriptScreen extends StatelessWidget {
  const TranscriptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TranscriptListBloc, TranscriptListState>(
      builder: (context, state) {
        final selected = state.selectedIds;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.transcript),
            actions: [
              if (selected.isEmpty)
                IconButton(
                  onPressed: () => _showStatusHelp(context),
                  icon: const Icon(Icons.help_outline),
                  tooltip: _isTurkish(context)
                      ? 'Statu ikonlari'
                      : 'Status icons',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              else ...[
                IconButton(
                  onPressed: () => context.read<TranscriptListBloc>().add(
                    const TranscriptListSelectionCleared(),
                  ),
                  icon: const Icon(Icons.close),
                  tooltip: l10n.cancel,
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context, selected.length),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.delete,
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: AppConstrainedBody(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSearchField(
                          hintText: l10n.searchRecordings,
                          onChanged: (value) => context
                              .read<TranscriptListBloc>()
                              .add(TranscriptListQueryChanged(value)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppSegmentedControl<TranscriptSort>(
                          value: state.sort,
                          segments: [
                            AppSegment(
                              value: TranscriptSort.newest,
                              label: l10n.newest,
                              icon: Icons.arrow_downward,
                            ),
                            AppSegment(
                              value: TranscriptSort.oldest,
                              label: l10n.oldest,
                              icon: Icons.arrow_upward,
                            ),
                            AppSegment(
                              value: TranscriptSort.longest,
                              label: l10n.longest,
                              icon: Icons.timer_outlined,
                            ),
                          ],
                          onChanged: (value) => context
                              .read<TranscriptListBloc>()
                              .add(TranscriptListSortChanged(value)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppSegmentedControl<TranscriptFilter>(
                          value: state.filter,
                          minSegmentWidth: 104,
                          segments: [
                            AppSegment(
                              value: TranscriptFilter.all,
                              label: l10n.all,
                            ),
                            AppSegment(
                              value: TranscriptFilter.ready,
                              label: l10n.statusReady,
                            ),
                            AppSegment(
                              value: TranscriptFilter.processing,
                              label: l10n.statusProcessing,
                            ),
                            AppSegment(
                              value: TranscriptFilter.issue,
                              label: l10n.statusIssue,
                            ),
                          ],
                          onChanged: (value) => context
                              .read<TranscriptListBloc>()
                              .add(TranscriptListFilterChanged(value)),
                        ),
                      ],
                    ),
                  ),
                  if (selected.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      selected: true,
                      child: AppSelectionBar(
                        label: '${selected.length} ${l10n.selected}',
                        action: AppButton(
                          label: l10n.delete,
                          icon: Icons.delete_outline,
                          onPressed: () =>
                              _confirmDelete(context, selected.length),
                          variant: AppButtonVariant.outline,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: state.items.isEmpty
                        ? EmptyState(
                            icon: Icons.description_outlined,
                            title: l10n.transcript,
                            description: state.query.isEmpty
                                ? l10n.noTranscriptAvailable
                                : l10n.noMatchingText,
                          )
                        : ListView.separated(
                            itemBuilder: (context, index) {
                              final item = state.items[index];
                              final transcript = item.transcript;
                              final isSelected = selected.contains(
                                transcript.id,
                              );
                              return _TranscriptCard(
                                transcript: transcript,
                                mergedText: item.mergedText,
                                selected: isSelected,
                                onTap: () {
                                  if (selected.isNotEmpty) {
                                    context.read<TranscriptListBloc>().add(
                                      TranscriptListSelectionToggled(
                                        transcript.id,
                                      ),
                                    );
                                  } else {
                                    _showTranscriptDetail(
                                      context,
                                      transcript.id,
                                    );
                                  }
                                },
                                onLongPress: () =>
                                    context.read<TranscriptListBloc>().add(
                                      TranscriptListSelectionToggled(
                                        transcript.id,
                                      ),
                                    ),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.sm + 2),
                            itemCount: state.items.length,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, int count) async {
    if (count == 0) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.deleteRecordingsTitle),
          content: Text(l10n.deleteRecordingsMessage(count)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if ((confirmed ?? false) && context.mounted) {
      context.read<TranscriptListBloc>().add(
        const TranscriptListSelectedDeleted(),
      );
    }
  }

  void _showTranscriptDetail(BuildContext context, String transcriptId) {
    final repository = context.read<TranscriptRepository>();
    final summaryService = context.read<SummaryService>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return BlocProvider(
          create: (_) => TranscriptDetailBloc(
            transcriptId: transcriptId,
            transcriptRepository: repository,
            summaryService: summaryService,
          )..add(const TranscriptDetailSubscriptionRequested()),
          child: const _TranscriptDetailSheet(),
        );
      },
    );
  }

  void _showStatusHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _StatusHelpSheet(),
    );
  }
}

class _StatusHelpSheet extends StatelessWidget {
  const _StatusHelpSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = [
      TranscriptStatus.recording,
      TranscriptStatus.transcribing,
      TranscriptStatus.completed,
      TranscriptStatus.transcriptionError,
    ];

    return AppModalListView(
      children: [
        Text(
          _isTurkish(context) ? 'Statu ikonlari' : 'Status icons',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final status in statuses) ...[
          _StatusHelpRow(status: status),
          if (status != statuses.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _StatusHelpRow extends StatelessWidget {
  const _StatusHelpRow({required this.status});

  final TranscriptStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(context, status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconBadge(icon: statusIcon(status), color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusLabel(context, status),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _statusHelpDescription(context, status),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TranscriptDetailSheet extends StatelessWidget {
  const _TranscriptDetailSheet();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TranscriptDetailBloc, TranscriptDetailState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        final l10n = context.l10n;
        final transcript = state.transcript;
        if (transcript == null) {
          return AppModalBody(child: Text(l10n.noTranscriptAvailable));
        }

        final recordedAt = transcript.recordedAt ?? transcript.createdAt;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.84,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return AppModalListView(
              controller: scrollController,
              children: [
                AppEditableTitle(
                  title: transcript.title,
                  placeholder: l10n.unnamed,
                  editTooltip: l10n.edit,
                  onSubmitted: (value) => context
                      .read<TranscriptDetailBloc>()
                      .add(TranscriptDetailTitleSubmitted(value)),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    TranscriptStatusPill(
                      status: transcript.status,
                      compact: true,
                    ),
                    MetricPill(
                      icon: Icons.calendar_today_outlined,
                      value: DateFormat('MMM d, HH:mm').format(recordedAt),
                      label: '',
                    ),
                    MetricPill(
                      icon: Icons.timer_outlined,
                      value: formatCompactDuration(transcript.durationSeconds),
                      label: l10n.duration,
                    ),
                    MetricPill(
                      icon: Icons.graphic_eq,
                      value: '${state.chunks.length}',
                      label: l10n.chunks,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                DefaultTabController(
                  length: 2,
                  child: TabBar(
                    onTap: (value) => context.read<TranscriptDetailBloc>().add(
                      TranscriptDetailTabChanged(value),
                    ),
                    tabs: [
                      Tab(text: l10n.transcript),
                      Tab(text: l10n.summary),
                    ],
                  ),
                ),
                const PremiumDivider(),
                if (state.tabIndex == 0)
                  _TranscriptTextTab(mergedText: state.mergedText)
                else
                  _SummaryTab(state: state),
              ],
            );
          },
        );
      },
    );
  }
}

class _TranscriptTextTab extends StatelessWidget {
  const _TranscriptTextTab({required this.mergedText});

  final String mergedText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mergedText.isEmpty)
          Text(
            l10n.noTranscriptAvailable,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          SelectableText(mergedText, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.state});

  final TranscriptDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: l10n.generateSummary,
          icon: Icons.auto_awesome,
          onPressed: state.mergedText.isEmpty
              ? null
              : () => context.read<TranscriptDetailBloc>().add(
                  const TranscriptDetailSummaryRequested(),
                ),
          isLoading: state.generatingSummary,
          expanded: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Text(
            state.summary?.summaryText ?? l10n.summaryPlaceholder,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: state.summary == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({
    required this.transcript,
    required this.mergedText,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final Transcript transcript;
  final String mergedText;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final recordedAt = transcript.recordedAt ?? transcript.createdAt;

    return GestureDetector(
      onLongPress: onLongPress,
      child: AppCard(
        onTap: onTap,
        selected: selected,
        semanticLabel: transcript.title ?? l10n.unnamed,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconBadge(
              icon: selected
                  ? Icons.check_circle
                  : statusIcon(transcript.status),
              color: selected
                  ? theme.colorScheme.primary
                  : statusColor(context, transcript.status),
              size: 42,
              iconSize: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transcript.title ?? l10n.unnamed,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      MetricPill(
                        icon: Icons.calendar_today_outlined,
                        value: DateFormat('MMM d, HH:mm').format(recordedAt),
                        label: '',
                      ),
                      MetricPill(
                        icon: Icons.timer_outlined,
                        value: formatCompactDuration(
                          transcript.durationSeconds,
                        ),
                        label: l10n.duration,
                      ),
                    ],
                  ),
                  if (mergedText.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm + 2),
                    Text(
                      mergedText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TranscriptStatusPill extends StatelessWidget {
  const TranscriptStatusPill({
    required this.status,
    super.key,
    this.compact = false,
  });

  final TranscriptStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      compact: compact,
      icon: statusIcon(status),
      label: statusLabel(context, status),
      color: statusColor(context, status),
    );
  }
}

String statusLabel(BuildContext context, TranscriptStatus status) {
  final l10n = context.l10n;
  return switch (displayStatusFor(status)) {
    TranscriptDisplayStatus.active => l10n.statusRecording,
    TranscriptDisplayStatus.processing => l10n.statusProcessing,
    TranscriptDisplayStatus.ready => l10n.statusReady,
    TranscriptDisplayStatus.issue => l10n.statusIssue,
  };
}

Color statusColor(BuildContext context, TranscriptStatus status) {
  final theme = Theme.of(context);
  return switch (displayStatusFor(status)) {
    TranscriptDisplayStatus.active => theme.colorScheme.error,
    TranscriptDisplayStatus.processing => AppTheme.amber,
    TranscriptDisplayStatus.ready => AppTheme.teal,
    TranscriptDisplayStatus.issue => theme.colorScheme.error,
  };
}

IconData statusIcon(TranscriptStatus status) {
  return switch (displayStatusFor(status)) {
    TranscriptDisplayStatus.active => Icons.mic,
    TranscriptDisplayStatus.processing => Icons.sync,
    TranscriptDisplayStatus.ready => Icons.check_circle,
    TranscriptDisplayStatus.issue => Icons.error_outline,
  };
}

String _statusHelpDescription(BuildContext context, TranscriptStatus status) {
  final turkish = _isTurkish(context);
  return switch (displayStatusFor(status)) {
    TranscriptDisplayStatus.active =>
      turkish ? 'Kayit devam ediyor.' : 'Recording is in progress.',
    TranscriptDisplayStatus.processing =>
      turkish ? 'Metin su an hazirlaniyor.' : 'Transcript is being prepared.',
    TranscriptDisplayStatus.ready =>
      turkish ? 'Metin kullanima hazir.' : 'Transcript is ready now.',
    TranscriptDisplayStatus.issue =>
      turkish ? 'Kontrol etmen gerekiyor.' : 'Needs your attention.',
  };
}

bool _isTurkish(BuildContext context) {
  return context.l10n.localeName.toLowerCase().startsWith('tr');
}
