import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/i18n/app_strings.dart';
import '../../shared/models/domain.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/text_utils.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/premium_widgets.dart';

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
              onPressed: () => _deleteSelected(app),
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
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<HistorySort>(
                        segments: const [
                          ButtonSegment(
                            value: HistorySort.newest,
                            label: Text('Yeni'),
                            icon: Icon(Icons.arrow_downward),
                          ),
                          ButtonSegment(
                            value: HistorySort.oldest,
                            label: Text('Eski'),
                            icon: Icon(Icons.arrow_upward),
                          ),
                          ButtonSegment(
                            value: HistorySort.longest,
                            label: Text('Uzun'),
                            icon: Icon(Icons.timer_outlined),
                          ),
                        ],
                        selected: {_sort},
                        onSelectionChanged: (value) =>
                            setState(() => _sort = value.first),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 12),
                AppCard(
                  selected: true,
                  showAccent: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: StatusPill(
                            icon: Icons.check_circle,
                            label: '${_selected.length} ${_strings.selected}',
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _deleteSelected(app),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(_strings.delete),
                      ),
                    ],
                  ),
                ),
              ],
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

  void _deleteSelected(AppController app) {
    for (final id in _selected) {
      app.removeTranscript(id);
    }
    setState(_selected.clear);
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
      selected: selected,
      showAccent: true,
      accentColor: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.secondary,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.48,
                    ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 14),
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
                  runSpacing: 6,
                  children: [
                    const _MiniBadge(label: 'Yerel', icon: Icons.storage),
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
          Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.50,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.70),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.teal),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
