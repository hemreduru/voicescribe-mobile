import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/utils/text_utils.dart';
import 'package:voicescribe_mobile/shared/widgets/app_button.dart';
import 'package:voicescribe_mobile/shared/widgets/app_card.dart';
import 'package:voicescribe_mobile/shared/widgets/app_page.dart';
import 'package:voicescribe_mobile/shared/widgets/app_segmented_control.dart';
import 'package:voicescribe_mobile/shared/widgets/app_text_field.dart';
import 'package:voicescribe_mobile/shared/widgets/premium_widgets.dart';

enum TranscriptSort { newest, oldest, longest }

enum TranscriptFilter { all, ready, processing, issue }

enum TranscriptDisplayStatus { active, processing, ready, issue }

class TranscriptScreen extends ConsumerStatefulWidget {
  const TranscriptScreen({super.key});

  @override
  ConsumerState<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends ConsumerState<TranscriptScreen> {
  String _query = '';
  TranscriptSort _sort = TranscriptSort.newest;
  TranscriptFilter _filter = TranscriptFilter.all;
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final transcriptState = ref.watch(
      appControllerProvider.select(
        (app) => (transcripts: app.transcripts, allChunks: app.allChunks),
      ),
    );
    final app = ref.read(appControllerProvider);
    final items = _buildTranscriptItems(
      transcripts: transcriptState.transcripts,
      textForTranscript: app.transcriptText,
    );

    _selected.removeWhere(
      (id) => !items.any((item) => item.transcript.id == id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transcript),
        actions: [
          if (_selected.isEmpty)
            IconButton(
              onPressed: () => _showStatusHelp(context),
              icon: const Icon(Icons.help_outline),
              tooltip: _isTurkish(context) ? 'Statü ikonları' : 'Status icons',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          else ...[
            IconButton(
              onPressed: () => setState(_selected.clear),
              icon: const Icon(Icons.close),
              tooltip: l10n.cancel,
            ),
            IconButton(
              onPressed: () => _confirmDelete(app),
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
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSegmentedControl<TranscriptSort>(
                      value: _sort,
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
                      onChanged: (value) => setState(() => _sort = value),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppSegmentedControl<TranscriptFilter>(
                      value: _filter,
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
                      onChanged: (value) => setState(() => _filter = value),
                    ),
                  ],
                ),
              ),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  selected: true,
                  child: AppSelectionBar(
                    label: '${_selected.length} ${l10n.selected}',
                    action: AppButton(
                      label: l10n.delete,
                      icon: Icons.delete_outline,
                      onPressed: () => _confirmDelete(app),
                      variant: AppButtonVariant.outline,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.description_outlined,
                        title: l10n.transcript,
                        description: _query.isEmpty
                            ? l10n.noTranscriptAvailable
                            : l10n.noMatchingText,
                      )
                    : ListView.separated(
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final transcript = item.transcript;
                          final selected = _selected.contains(transcript.id);
                          return _TranscriptCard(
                            transcript: transcript,
                            mergedText: item.mergedText,
                            selected: selected,
                            onTap: () {
                              if (_selected.isNotEmpty) {
                                _toggleSelected(transcript.id);
                              } else {
                                _showTranscriptDetail(context, transcript.id);
                              }
                            },
                            onLongPress: () => _toggleSelected(transcript.id),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.sm + 2),
                        itemCount: items.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesFilter(TranscriptStatus status) {
    final display = displayStatusFor(status);
    return switch (_filter) {
      TranscriptFilter.all => true,
      TranscriptFilter.ready => display == TranscriptDisplayStatus.ready,
      TranscriptFilter.processing =>
        display == TranscriptDisplayStatus.processing ||
            display == TranscriptDisplayStatus.active,
      TranscriptFilter.issue => display == TranscriptDisplayStatus.issue,
    };
  }

  List<_TranscriptListItem> _buildTranscriptItems({
    required List<Transcript> transcripts,
    required String Function(String transcriptId) textForTranscript,
  }) {
    final query = _query.trim().toLowerCase();
    final items = <_TranscriptListItem>[];

    for (final transcript in transcripts) {
      if (!_matchesFilter(transcript.status)) {
        continue;
      }

      final mergedText = textForTranscript(transcript.id);
      final title = (transcript.title ?? '').toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          title.contains(query) ||
          mergedText.toLowerCase().contains(query);
      if (!matchesQuery) {
        continue;
      }

      items.add(
        _TranscriptListItem(transcript: transcript, mergedText: mergedText),
      );
    }

    items.sort((a, b) {
      final aTranscript = a.transcript;
      final bTranscript = b.transcript;
      return switch (_sort) {
        TranscriptSort.newest =>
          (bTranscript.recordedAt ?? bTranscript.createdAt).compareTo(
            aTranscript.recordedAt ?? aTranscript.createdAt,
          ),
        TranscriptSort.oldest =>
          (aTranscript.recordedAt ?? aTranscript.createdAt).compareTo(
            bTranscript.recordedAt ?? bTranscript.createdAt,
          ),
        TranscriptSort.longest => bTranscript.durationSeconds.compareTo(
          aTranscript.durationSeconds,
        ),
      };
    });

    return items;
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _confirmDelete(AppController app) async {
    final count = _selected.length;
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

    if (confirmed != true) {
      return;
    }
    for (final id in _selected.toList()) {
      app.removeTranscript(id);
    }
    if (mounted) {
      setState(_selected.clear);
    }
  }

  void _showTranscriptDetail(BuildContext context, String transcriptId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _TranscriptDetailSheet(transcriptId: transcriptId),
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
          _isTurkish(context) ? 'Statü ikonları' : 'Status icons',
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

class _TranscriptDetailSheet extends ConsumerStatefulWidget {
  const _TranscriptDetailSheet({required this.transcriptId});

  final String transcriptId;

  @override
  ConsumerState<_TranscriptDetailSheet> createState() =>
      _TranscriptDetailSheetState();
}

class _TranscriptDetailSheetState
    extends ConsumerState<_TranscriptDetailSheet> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final l10n = context.l10n;
    final transcript = app.transcripts
        .where((item) => item.id == widget.transcriptId)
        .firstOrNull;
    if (transcript == null) {
      return AppModalBody(child: Text(l10n.noTranscriptAvailable));
    }

    final chunks = app.chunksFor(transcript.id);
    final mergedText = mergeTranscriptChunks(chunks);
    final summary = app.latestSummaryFor(transcript.id);
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
              onSubmitted: (value) {
                ref
                    .read(appControllerProvider)
                    .updateTranscriptTitle(transcript.id, value);
              },
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
                  value: '${chunks.length}',
                  label: l10n.chunks,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            DefaultTabController(
              length: 2,
              child: TabBar(
                onTap: (value) => setState(() => _tabIndex = value),
                tabs: [
                  Tab(text: l10n.transcript),
                  Tab(text: l10n.summary),
                ],
              ),
            ),
            const PremiumDivider(),
            if (_tabIndex == 0)
              _TranscriptTextTab(mergedText: mergedText)
            else
              _SummaryTab(
                transcript: transcript,
                mergedText: mergedText,
                summary: summary,
              ),
          ],
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

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab({
    required this.transcript,
    required this.mergedText,
    required this.summary,
  });

  final Transcript transcript;
  final String mergedText;
  final Summary? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final app = ref.watch(appControllerProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: l10n.generateSummary,
          icon: Icons.auto_awesome,
          onPressed: mergedText.isEmpty
              ? null
              : () => ref
                    .read(appControllerProvider)
                    .generateSummaryForTranscript(transcript.id),
          isLoading: app.summaryGenerating,
          expanded: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Text(
            summary?.summaryText ?? l10n.summaryPlaceholder,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: summary == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _TranscriptListItem {
  const _TranscriptListItem({
    required this.transcript,
    required this.mergedText,
  });

  final Transcript transcript;
  final String mergedText;
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

TranscriptDisplayStatus displayStatusFor(TranscriptStatus status) {
  return switch (status) {
    TranscriptStatus.recording => TranscriptDisplayStatus.active,
    TranscriptStatus.transcriptionError => TranscriptDisplayStatus.issue,
    TranscriptStatus.completed => TranscriptDisplayStatus.ready,
    TranscriptStatus.transcribing ||
    TranscriptStatus.transcriptionCompleted ||
    TranscriptStatus.empty => TranscriptDisplayStatus.processing,
  };
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
      turkish ? 'Kayıt devam ediyor.' : 'Recording is in progress.',
    TranscriptDisplayStatus.processing =>
      turkish ? 'Metin şu an hazırlanıyor.' : 'Transcript is being prepared.',
    TranscriptDisplayStatus.ready =>
      turkish ? 'Metin kullanıma hazır.' : 'Transcript is ready now.',
    TranscriptDisplayStatus.issue =>
      turkish ? 'Kontrol etmen gerekiyor.' : 'Needs your attention.',
  };
}

bool _isTurkish(BuildContext context) {
  return context.l10n.localeName.toLowerCase().startsWith('tr');
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
