import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/utils/text_utils.dart';
import 'package:voicescribe_mobile/shared/widgets/app_card.dart';
import 'package:voicescribe_mobile/shared/widgets/premium_widgets.dart';

class TranscriptScreen extends ConsumerStatefulWidget {
  const TranscriptScreen({super.key});

  @override
  ConsumerState<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends ConsumerState<TranscriptScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final app = ref.watch(appControllerProvider);
    final filtered = app.transcripts.where((transcript) {
      final text = app.transcriptText(transcript.id).toLowerCase();
      final title = (transcript.title ?? '').toLowerCase();
      final query = _query.toLowerCase();
      return query.isEmpty || title.contains(query) || text.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transcript)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.searchRecordings,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.description_outlined,
                        title: l10n.transcript,
                        description: _query.isEmpty
                            ? l10n.noTranscriptAvailable
                            : l10n.noMatchingText,
                      )
                    : ListView.separated(
                        itemBuilder: (context, index) {
                          final transcript = filtered[index];
                          return _TranscriptCard(
                            transcript: transcript,
                            mergedText: app.transcriptText(transcript.id),
                            chunks: app.chunksFor(transcript.id),
                            onTap: () =>
                                _showTranscriptDetail(context, app, transcript),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemCount: filtered.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTranscriptDetail(
    BuildContext context,
    AppController app,
    Transcript transcript,
  ) {
    final chunks = app.chunksFor(transcript.id);
    final mergedText = mergeTranscriptChunks(chunks);
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              children: [
                Text(
                  transcript.title ?? l10n.unnamed,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(
                      compact: true,
                      icon: _statusIcon(transcript.status),
                      label: localizedStatusLabel(l10n, transcript.status.key),
                      color: _statusColor(context, transcript.status),
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
                const PremiumDivider(),
                if (mergedText.isEmpty)
                  Text(
                    l10n.noTranscriptAvailable,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  )
                else
                  SelectableText(
                    mergedText,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                if (chunks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: l10n.chunks,
                    subtitle: '${chunks.length} parça',
                  ),
                  const SizedBox(height: 8),
                  ...chunks.map(
                    (chunk) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        showAccent: true,
                        accentColor: theme.colorScheme.secondary,
                        child: Text(
                          chunk.text.isEmpty
                              ? l10n.noTranscriptAvailable
                              : chunk.text,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({
    required this.transcript,
    required this.mergedText,
    required this.chunks,
    required this.onTap,
  });

  final Transcript transcript;
  final String mergedText;
  final List<TranscriptChunk> chunks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final recordedAt = transcript.recordedAt ?? transcript.createdAt;
    return AppCard(
      onTap: onTap,
      showAccent: true,
      accentColor: _statusColor(context, transcript.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  transcript.title ?? l10n.unnamed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusPill(
                compact: true,
                icon: _statusIcon(transcript.status),
                label: localizedStatusLabel(l10n, transcript.status.key),
                color: _statusColor(context, transcript.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
          if (mergedText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              mergedText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

Color _statusColor(BuildContext context, TranscriptStatus status) {
  final theme = Theme.of(context);
  return switch (status) {
    TranscriptStatus.completed => AppTheme.teal,
    TranscriptStatus.transcriptionError => theme.colorScheme.error,
    TranscriptStatus.recording ||
    TranscriptStatus.transcribing => AppTheme.amber,
    TranscriptStatus.empty => theme.colorScheme.outline,
  };
}

IconData _statusIcon(TranscriptStatus status) {
  return switch (status) {
    TranscriptStatus.completed => Icons.check_circle,
    TranscriptStatus.transcriptionError => Icons.error,
    TranscriptStatus.recording => Icons.mic,
    TranscriptStatus.transcribing => Icons.sync,
    TranscriptStatus.empty => Icons.radio_button_unchecked,
  };
}
