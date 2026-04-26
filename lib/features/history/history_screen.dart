import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/i18n/app_strings.dart';
import '../../shared/models/domain.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/utils/text_utils.dart';
import '../../shared/widgets/app_card.dart';

enum HistorySort { newest, oldest, longest }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const _strings = AppStrings();
  String _query = '';
  HistorySort _sort = HistorySort.newest;
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final items =
        app.transcripts.where((transcript) {
          final query = _query.toLowerCase();
          return query.isEmpty ||
              (transcript.title ?? '').toLowerCase().contains(query) ||
              app.transcriptText(transcript.id).toLowerCase().contains(query);
        }).toList()..sort((a, b) {
          return switch (_sort) {
            HistorySort.newest => b.createdAt.compareTo(a.createdAt),
            HistorySort.oldest => a.createdAt.compareTo(b.createdAt),
            HistorySort.longest => b.durationSeconds.compareTo(
              a.durationSeconds,
            ),
          };
        });

    return Scaffold(
      appBar: AppBar(
        title: Text(_strings.history),
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              onPressed: () {
                for (final id in _selected) {
                  app.removeTranscript(id);
                }
                setState(_selected.clear);
              },
              icon: const Icon(Icons.delete),
              tooltip: _strings.delete,
            ),
        ],
      ),
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
              SegmentedButton<HistorySort>(
                segments: const [
                  ButtonSegment(value: HistorySort.newest, label: Text('Yeni')),
                  ButtonSegment(value: HistorySort.oldest, label: Text('Eski')),
                  ButtonSegment(
                    value: HistorySort.longest,
                    label: Text('Uzun'),
                  ),
                ],
                selected: {_sort},
                onSelectionChanged: (value) =>
                    setState(() => _sort = value.first),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.folder_open,
                        title: _strings.noRecordings,
                        description: _query.isEmpty
                            ? _strings.noRecordings
                            : _strings.noMatchingText,
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final transcript = items[index];
                          return _HistoryCard(
                            transcript: transcript,
                            selected: _selected.contains(transcript.id),
                            hasTranscript: app
                                .transcriptText(transcript.id)
                                .isNotEmpty,
                            onTap: () {
                              setState(() {
                                if (_selected.contains(transcript.id)) {
                                  _selected.remove(transcript.id);
                                } else {
                                  _selected.add(transcript.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.transcript,
    required this.selected,
    required this.hasTranscript,
    required this.onTap,
  });

  final Transcript transcript;
  final bool selected;
  final bool hasTranscript;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = transcript.recordedAt ?? transcript.createdAt;
    return AppCard(
      onTap: onTap,
      backgroundColor: selected ? theme.colorScheme.primaryContainer : null,
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transcript.title ?? const AppStrings().unnamed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('dd.MM.yyyy HH:mm').format(date)} • ${formatDuration(transcript.durationSeconds)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    const _MiniBadge(label: 'Synced', icon: Icons.cloud_done),
                    if (hasTranscript)
                      const _MiniBadge(
                        label: 'Transkript',
                        icon: Icons.description,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 14),
      label: Text(label),
      labelStyle: theme.textTheme.labelSmall,
    );
  }
}
