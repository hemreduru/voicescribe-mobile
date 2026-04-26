import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/i18n/app_strings.dart';
import '../../shared/models/domain.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/utils/text_utils.dart';
import '../../shared/widgets/app_card.dart';

class TranscriptScreen extends ConsumerStatefulWidget {
  const TranscriptScreen({super.key});

  @override
  ConsumerState<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends ConsumerState<TranscriptScreen> {
  static const _strings = AppStrings();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final filtered = app.transcripts.where((transcript) {
      final text = app.transcriptText(transcript.id).toLowerCase();
      final title = (transcript.title ?? '').toLowerCase();
      final query = _query.toLowerCase();
      return query.isEmpty || title.contains(query) || text.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(_strings.transcript)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: _strings.searchRecordings,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.description_outlined,
                        title: _strings.transcript,
                        description: _query.isEmpty
                            ? _strings.noTranscriptAvailable
                            : _strings.noMatchingText,
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
                  transcript.title ?? _strings.unnamed,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(_strings.statusLabel(transcript.status.key)),
                    ),
                    Chip(
                      label: Text(
                        formatCompactDuration(transcript.durationSeconds),
                      ),
                    ),
                    Chip(label: Text('${chunks.length} chunk')),
                  ],
                ),
                const SizedBox(height: 16),
                if (mergedText.isEmpty)
                  Text(
                    _strings.noTranscriptAvailable,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  )
                else
                  SelectableText(
                    mergedText,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                if (chunks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Chunks',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...chunks.map(
                    (chunk) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        child: Text(
                          chunk.text.isEmpty
                              ? _strings.noTranscriptAvailable
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
    final theme = Theme.of(context);
    final recordedAt = transcript.recordedAt ?? transcript.createdAt;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  transcript.title ?? const AppStrings().unnamed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusBadge(status: transcript.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('MMM d, HH:mm').format(recordedAt)} • ${formatCompactDuration(transcript.durationSeconds)} • ${chunks.length} chunk',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TranscriptStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      TranscriptStatus.completed => Colors.green,
      TranscriptStatus.transcriptionError => theme.colorScheme.error,
      TranscriptStatus.recording ||
      TranscriptStatus.transcribing => Colors.orange,
      TranscriptStatus.empty => theme.colorScheme.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        const AppStrings().statusLabel(status.key),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
