import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/models/meeting_summary.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/domain/utils/text_utils.dart';
import 'package:voicescribe_mobile/l10n/app_localizations.dart';
import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/theme/premium_tokens.dart';
import 'package:voicescribe_mobile/ui/core/widgets/adaptive_master_detail.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_button.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_card.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_page.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_segmented_control.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_skeleton.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_text_field.dart';
import 'package:voicescribe_mobile/ui/core/widgets/premium_widgets.dart';
import 'package:voicescribe_mobile/ui/features/recording/bloc/recording_bloc.dart';
import 'package:voicescribe_mobile/ui/features/transcript/bloc/transcript_detail_bloc.dart';
import 'package:voicescribe_mobile/ui/features/transcript/bloc/transcript_list_bloc.dart';
import 'package:voicescribe_mobile/ui/features/transcript/widgets/meeting_summary_view.dart';

class TranscriptScreen extends StatelessWidget {
  const TranscriptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TranscriptListBloc, TranscriptListState>(
      buildWhen: (previous, current) =>
          (previous.snapshot == null) != (current.snapshot == null) ||
          previous.items != current.items ||
          previous.selectedIds != current.selectedIds ||
          previous.selectedTranscriptId != current.selectedTranscriptId ||
          previous.query != current.query ||
          previous.sort != current.sort ||
          previous.filter != current.filter,
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
                  tooltip: l10n.statusIconsTitle,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final twoPane =
                    constraints.maxWidth >= AppPanes.twoPaneBreakpoint;
                final master = _TranscriptMaster(
                  state: state,
                  twoPane: twoPane,
                );
                if (twoPane) {
                  // Wide layout: list stays visible, detail updates in place.
                  return AdaptiveMasterDetail<String>(
                    isTwoPane: true,
                    master: master,
                    selected: state.selectedTranscriptId,
                    emptyState: _detailEmptyState(context),
                    detailBuilder: (context, id) =>
                        _TranscriptDetailPane(transcriptId: id),
                  );
                }
                // Compact: drive the existing modal sheet from the same
                // selected-id so phone behavior is unchanged.
                return BlocListener<TranscriptListBloc, TranscriptListState>(
                  listenWhen: (previous, current) =>
                      previous.selectedTranscriptId !=
                          current.selectedTranscriptId &&
                      current.selectedTranscriptId != null,
                  listener: (context, state) => _openTranscriptModal(
                    context,
                    state.selectedTranscriptId!,
                  ),
                  child: master,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _detailEmptyState(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      icon: Icons.touch_app_outlined,
      title: l10n.transcript,
      description: l10n.noTranscriptAvailable,
    );
  }

  void _openTranscriptModal(BuildContext context, String transcriptId) {
    final repository = context.read<TranscriptRepository>();
    final summaryService = context.read<SummaryService>();
    final syncQueueService = context.read<SyncQueueService>();
    final listBloc = context.read<TranscriptListBloc>();
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
            syncQueueService: syncQueueService,
          )..add(const TranscriptDetailSubscriptionRequested()),
          child: const _TranscriptDetailSheet(),
        );
      },
    ).whenComplete(() {
      // Keep the single selected-id in sync when the sheet is dismissed.
      listBloc.add(const TranscriptListDetailClosed());
    });
  }

  void _showStatusHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _StatusHelpSheet(),
    );
  }
}

/// The persistent transcript list (search, filters, list). Reads the
/// [TranscriptListBloc] from context. On compact it is the whole screen; on wide
/// it is the master pane.
class _TranscriptMaster extends StatelessWidget {
  const _TranscriptMaster({required this.state, required this.twoPane});

  final TranscriptListState state;
  final bool twoPane;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = state.selectedIds;
    return AppConstrainedBody(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSearchField(
                  hintText: l10n.searchRecordings,
                  onChanged: (value) => context.read<TranscriptListBloc>().add(
                    TranscriptListQueryChanged(value),
                  ),
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
                  onChanged: (value) => context.read<TranscriptListBloc>().add(
                    TranscriptListSortChanged(value),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSegmentedControl<TranscriptFilter>(
                  value: state.filter,
                  minSegmentWidth: 104,
                  segments: [
                    AppSegment(value: TranscriptFilter.all, label: l10n.all),
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
                  onChanged: (value) => context.read<TranscriptListBloc>().add(
                    TranscriptListFilterChanged(value),
                  ),
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
                  onPressed: () => _confirmDelete(context, selected.length),
                  variant: AppButtonVariant.outline,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refreshFromBackend(context),
              child: state.snapshot == null
                  ? const AppSkeletonList()
                  : state.items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        EmptyState(
                          icon: Icons.description_outlined,
                          title: l10n.transcript,
                          description: state.query.isEmpty
                              ? l10n.noTranscriptAvailable
                              : l10n.noMatchingText,
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        final transcript = item.transcript;
                        final isSelected = selected.contains(transcript.id);
                        final isActive =
                            twoPane &&
                            state.selectedTranscriptId == transcript.id;
                        return _TranscriptCard(
                          transcript: transcript,
                          mergedText: item.mergedText,
                          completedChunkCount: item.completedChunkCount,
                          totalChunkCount: item.totalChunkCount,
                          selected: isSelected,
                          active: isActive,
                          onTap: () {
                            if (selected.isNotEmpty) {
                              context.read<TranscriptListBloc>().add(
                                TranscriptListSelectionToggled(transcript.id),
                              );
                            } else {
                              AppHaptics.selection();
                              context.read<TranscriptListBloc>().add(
                                TranscriptListDetailOpened(transcript.id),
                              );
                            }
                          },
                          onLongPress: () =>
                              context.read<TranscriptListBloc>().add(
                                TranscriptListSelectionToggled(transcript.id),
                              ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm + 2),
                      itemCount: state.items.length,
                    ),
            ),
          ),
        ],
      ),
    );
  }
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

Future<void> _refreshFromBackend(BuildContext context) async {
  final completer = Completer<void>();
  context.read<TranscriptListBloc>().add(
    TranscriptListRefreshRequested(completer: completer),
  );
  try {
    await completer.future;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.refreshFailed)));
    }
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
          context.l10n.statusIconsTitle,
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

class _TranscriptionErrorBanner extends StatelessWidget {
  const _TranscriptionErrorBanner({this.onRetry, this.isRetrying = false});

  final VoidCallback? onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.transcriptionFailedRetry,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null || isRetrying)
            AppButton(
              label: isRetrying
                  ? context.l10n.retrying
                  : context.l10n.retryTranscription,
              icon: isRetrying ? Icons.hourglass_empty : Icons.refresh,
              onPressed: isRetrying ? null : onRetry,
              variant: AppButtonVariant.outline,
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
        ],
      ),
    );
  }
}

/// Humanizes a remaining-time estimate into a localized, rounded phrase like
/// "1 dakika" / "30 saniye" (diffForHumans style) — paired with the
/// `etaRemaining` frame to read "~1 dakika kaldı".
String humanizeEtaUnit(AppLocalizations l10n, Duration remaining) {
  final seconds = remaining.inSeconds;
  if (seconds < 60) {
    // Round to the nearest 5s (min 5) so it doesn't jitter every second.
    final rounded = (seconds / 5).round() * 5;
    return l10n.etaUnitSeconds(rounded < 5 ? 5 : rounded);
  }
  if (seconds < 3600) {
    return l10n.etaUnitMinutes((seconds / 60).round());
  }
  return l10n.etaUnitHours((seconds / 3600).round());
}

class _TranscriptionProgressBar extends StatelessWidget {
  const _TranscriptionProgressBar({
    required this.completed,
    required this.total,
    required this.isVisible,
    this.remaining,
  });

  final int completed;
  final int total;
  final bool isVisible;

  /// Device-specific estimate of time left; when set, shown as "~X kaldı"
  /// next to the chunk count.
  final Duration? remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final percent = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      curve: isVisible ? Curves.easeOut : Curves.easeIn,
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: theme
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation(
                          statusColor(context, TranscriptStatus.transcribing),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.transcriptionProgressPercent((percent * 100).round()),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              remaining == null || remaining!.inSeconds <= 0
                  ? l10n.transcriptionProgressChunks(completed, total)
                  : '${l10n.transcriptionProgressChunks(completed, total)} · '
                        '${l10n.etaRemaining(humanizeEtaUnit(l10n, remaining!))}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared body children for the transcript detail, used by both the compact
/// modal sheet and the tablet detail pane. [onAfterRetry] is invoked after a
/// retry is dispatched (the sheet pops; the pane closes its selection).
List<Widget> _transcriptDetailChildren(
  BuildContext context,
  TranscriptDetailState state,
  RecordingState recordingState, {
  required VoidCallback onAfterRetry,
}) {
  final l10n = context.l10n;
  final transcript = state.transcript!;
  final recordedAt = transcript.recordedAt ?? transcript.createdAt;
  final isProcessing =
      displayStatusFor(transcript.status) == TranscriptDisplayStatus.processing;
  final isError = transcript.status == TranscriptStatus.transcriptionError;
  final hasRetryingChunks = state.chunks.any(
    (c) => recordingState.retryingChunkIds.contains(c.id),
  );

  return [
    AppEditableTitle(
      title: transcript.title,
      placeholder: l10n.unnamed,
      editTooltip: l10n.edit,
      onSubmitted: (value) => context.read<TranscriptDetailBloc>().add(
        TranscriptDetailTitleSubmitted(value),
      ),
    ),
    const SizedBox(height: AppSpacing.md),
    Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        TranscriptStatusPill(status: transcript.status, compact: true),
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
    if (isProcessing) ...[
      const SizedBox(height: AppSpacing.md),
      _TranscriptionProgressBar(
        completed: state.completedChunkCount,
        total: state.totalChunkCount,
        isVisible: isProcessing,
        remaining:
            (recordingState.currentTranscript?.id == transcript.id &&
                recordingState.isTranscribing)
            ? recordingState.estimatedTranscriptionRemaining
            : null,
      ),
    ],
    if (isError) ...[
      const SizedBox(height: AppSpacing.md),
      _TranscriptionErrorBanner(
        isRetrying: hasRetryingChunks,
        onRetry: hasRetryingChunks
            ? null
            : () {
                final chunkIds = state.chunks
                    .where((c) => c.transcriptionError != null)
                    .map((c) => c.id)
                    .toList();
                context.read<RecordingBloc>().add(
                  RecordingChunkRetryRequested(
                    transcriptId: transcript.id,
                    chunkIds: chunkIds,
                  ),
                );
              },
      ),
    ],
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
      _TranscriptTextTab(
        mergedText: state.mergedText,
        canRetry: isError,
        isRetrying: hasRetryingChunks,
        onRetry: isError && !hasRetryingChunks
            ? () {
                final chunkIds = state.chunks
                    .where((c) => c.transcriptionError != null)
                    .map((c) => c.id)
                    .toList();
                context.read<RecordingBloc>().add(
                  RecordingChunkRetryRequested(
                    transcriptId: transcript.id,
                    chunkIds: chunkIds,
                  ),
                );
                onAfterRetry();
              }
            : null,
      )
    else
      _SummaryTab(state: state),
  ];
}

/// Wires the recording + detail blocs and delegates to [builder] once the
/// states are available. Shared by the modal sheet and the tablet pane.
class _TranscriptDetailScope extends StatelessWidget {
  const _TranscriptDetailScope({required this.builder});

  final Widget Function(
    BuildContext context,
    TranscriptDetailState state,
    RecordingState recordingState,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordingBloc, RecordingState>(
      buildWhen: (previous, current) =>
          previous.retryingChunkIds != current.retryingChunkIds ||
          previous.allChunks != current.allChunks ||
          previous.realtimeFactor != current.realtimeFactor ||
          previous.currentTranscript?.id != current.currentTranscript?.id,
      builder: (context, recordingState) {
        return BlocConsumer<TranscriptDetailBloc, TranscriptDetailState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          },
          buildWhen: (previous, current) =>
              previous.transcript != current.transcript ||
              previous.chunks != current.chunks ||
              previous.summary != current.summary ||
              previous.mergedText != current.mergedText ||
              previous.tabIndex != current.tabIndex ||
              previous.generatingSummary != current.generatingSummary ||
              previous.summaryProgress != current.summaryProgress ||
              previous.completedChunkCount != current.completedChunkCount ||
              previous.totalChunkCount != current.totalChunkCount,
          builder: (context, state) => builder(context, state, recordingState),
        );
      },
    );
  }
}

class _TranscriptDetailSheet extends StatelessWidget {
  const _TranscriptDetailSheet();

  @override
  Widget build(BuildContext context) {
    return _TranscriptDetailScope(
      builder: (context, state, recordingState) {
        final l10n = context.l10n;
        if (state.transcript == null) {
          return AppModalBody(child: Text(l10n.noTranscriptAvailable));
        }
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.84,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return AppModalListView(
              controller: scrollController,
              children: _transcriptDetailChildren(
                context,
                state,
                recordingState,
                onAfterRetry: () => Navigator.of(context).pop(),
              ),
            );
          },
        );
      },
    );
  }
}

/// Tablet detail pane: same content as the modal sheet, hosted beside the
/// master list. Creates its own [TranscriptDetailBloc] keyed by [transcriptId]
/// (the surrounding [AnimatedSwitcher] keys this subtree, so it rebuilds when
/// the selection changes).
class _TranscriptDetailPane extends StatelessWidget {
  const _TranscriptDetailPane({required this.transcriptId});

  final String transcriptId;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<TranscriptRepository>();
    final summaryService = context.read<SummaryService>();
    final syncQueueService = context.read<SyncQueueService>();
    return BlocProvider(
      create: (_) => TranscriptDetailBloc(
        transcriptId: transcriptId,
        transcriptRepository: repository,
        summaryService: summaryService,
        syncQueueService: syncQueueService,
      )..add(const TranscriptDetailSubscriptionRequested()),
      child: const _TranscriptDetailPaneBody(),
    );
  }
}

class _TranscriptDetailPaneBody extends StatelessWidget {
  const _TranscriptDetailPaneBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _TranscriptDetailScope(
      builder: (context, state, recordingState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.sm,
                0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => context.read<TranscriptListBloc>().add(
                    const TranscriptListDetailClosed(),
                  ),
                  icon: const Icon(Icons.close),
                  tooltip: l10n.cancel,
                ),
              ),
            ),
            Expanded(
              child: state.transcript == null
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: AppSkeletonList(itemCount: 4),
                    )
                  : AppPageListView(
                      children: _transcriptDetailChildren(
                        context,
                        state,
                        recordingState,
                        onAfterRetry: () => context
                            .read<TranscriptListBloc>()
                            .add(const TranscriptListDetailClosed()),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TranscriptTextTab extends StatelessWidget {
  const _TranscriptTextTab({
    required this.mergedText,
    required this.canRetry,
    required this.onRetry,
    this.isRetrying = false,
  });

  final String mergedText;
  final bool canRetry;
  final VoidCallback? onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (mergedText.isEmpty && canRetry) {
      return _TranscriptionRetryCta(onRetry: onRetry, isRetrying: isRetrying);
    }

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

class _TranscriptionRetryCta extends StatelessWidget {
  const _TranscriptionRetryCta({this.onRetry, this.isRetrying = false});

  final VoidCallback? onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRetrying ? Icons.hourglass_empty : Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isRetrying ? l10n.retrying : l10n.transcriptionFailedRetry,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: isRetrying ? l10n.retrying : l10n.retryTranscription,
            icon: isRetrying ? Icons.hourglass_empty : Icons.refresh,
            onPressed: isRetrying ? null : onRetry,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.state});

  final TranscriptDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
        if (state.generatingSummary && state.summaryProgress != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.summarizingProgress(
              state.summaryProgress!.current,
              state.summaryProgress!.total,
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _summaryBody(context),
      ],
    );
  }

  Widget _summaryBody(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = state.summary;

    if (summary == null) {
      return AppCard(
        child: Text(
          l10n.summaryPlaceholder,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final structured = MeetingSummary.tryParse(summary.summaryText);
    if (structured != null) {
      return MeetingSummaryView(
        summary: structured,
        providerKey: summary.providerKey,
      );
    }

    // A summary that was meant to be structured but didn't parse must NEVER be
    // shown as raw JSON. Show a clean, actionable message instead.
    if (MeetingSummary.looksLikeJson(summary.summaryText)) {
      return AppCard(
        child: Text(
          l10n.summaryUnavailable,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Genuine legacy plain-text summaries render as text.
    return AppCard(
      child: Text(
        summary.summaryText,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
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
    this.active = false,
    this.completedChunkCount = 0,
    this.totalChunkCount = 0,
  });

  final Transcript transcript;
  final String mergedText;
  final bool selected;

  /// Whether this transcript is the one currently open in the tablet detail
  /// pane. Highlights the card (without the multi-select check icon).
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final int completedChunkCount;
  final int totalChunkCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final recordedAt = transcript.recordedAt ?? transcript.createdAt;
    final isProcessing =
        displayStatusFor(transcript.status) ==
        TranscriptDisplayStatus.processing;
    // Show the live, device-specific ETA only on the transcript currently being
    // transcribed (the active recording session). `select` keeps rebuilds
    // scoped to this value.
    final remaining = context.select<RecordingBloc, Duration?>((bloc) {
      final s = bloc.state;
      return (s.currentTranscript?.id == transcript.id && s.isTranscribing)
          ? s.estimatedTranscriptionRemaining
          : null;
    });

    return GestureDetector(
      onLongPress: onLongPress,
      child: AppCard(
        onTap: onTap,
        selected: selected || active,
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
                  if (isProcessing) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _TranscriptionProgressBar(
                      completed: completedChunkCount,
                      total: totalChunkCount,
                      isVisible: isProcessing,
                      remaining: remaining,
                    ),
                  ],
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

/// A lightweight shimmer placeholder shown while the first transcript snapshot
/// loads, so the list fades in instead of popping from blank to content.
