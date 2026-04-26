import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/i18n/app_strings.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/text_utils.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/premium_widgets.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  static const _strings = AppStrings();
  String _provider = 'local';
  String _length = 'medium';
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_strings.summary),
        actions: [
          IconButton(
            onPressed: _openSummarySettings,
            icon: const Icon(Icons.tune),
            tooltip: _strings.summarySettings,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AppCard(
              showAccent: true,
              accentColor: latestText.isEmpty ? AppTheme.amber : AppTheme.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: _strings.latestTranscript,
                    subtitle: latestTranscript == null
                        ? _strings.noTranscriptAvailable
                        : DateFormat('d MMMM HH:mm').format(
                            latestTranscript.recordedAt ??
                                latestTranscript.createdAt,
                          ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: Icon(_providerIcon(), size: 17),
                        label: Text('${_providerLabel()} • ${_lengthLabel()}'),
                        onPressed: _openSummarySettings,
                      ),
                      if (latestText.isNotEmpty)
                        StatusPill(
                          icon: Icons.check_circle,
                          label: _strings.readyToSummarize,
                          color: AppTheme.teal,
                        ),
                      if (latestTranscript != null)
                        MetricPill(
                          icon: Icons.timer_outlined,
                          value: formatCompactDuration(
                            latestTranscript.durationSeconds,
                          ),
                          label: _strings.duration,
                        ),
                      if (latestTranscript != null)
                        MetricPill(
                          icon: Icons.graphic_eq,
                          value: '$latestChunks',
                          label: _strings.chunks,
                          color: AppTheme.amber,
                        ),
                    ],
                  ),
                  const PremiumDivider(),
                  Text(
                    latestTranscript?.title ?? _strings.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    latestText.isEmpty
                        ? _strings.summaryPlaceholder
                        : latestText,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: latestText.isEmpty || _generating
                  ? null
                  : _simulateSummary,
              icon: _generating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_strings.generateSummary),
            ),
            const SizedBox(height: 18),
            AppCard(
              showAccent: true,
              accentColor: theme.colorScheme.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    icon: Icons.auto_awesome,
                    label: _strings.noSummaryYet,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _strings.summaryPlaceholder,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
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
    setState(() => _generating = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _generating = false);
    }
  }

  void _openSummarySettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _strings.summarySettings,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Motor',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'local',
                          label: Text(_strings.local),
                          icon: const Icon(Icons.storage),
                        ),
                        ButtonSegment(
                          value: 'cloud',
                          label: Text(_strings.cloud),
                          icon: const Icon(Icons.cloud),
                        ),
                      ],
                      selected: {_provider},
                      onSelectionChanged: (value) {
                        setState(() => _provider = value.first);
                        modalSetState(() {});
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Uzunluk',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'short',
                          label: Text(_strings.short),
                        ),
                        ButtonSegment(
                          value: 'medium',
                          label: Text(_strings.medium),
                        ),
                        ButtonSegment(
                          value: 'long',
                          label: Text(_strings.long),
                        ),
                      ],
                      selected: {_length},
                      onSelectionChanged: (value) {
                        setState(() => _length = value.first);
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
    return switch (_provider) {
      'cloud' => _strings.cloud,
      _ => _strings.local,
    };
  }

  String _lengthLabel() {
    return switch (_length) {
      'short' => _strings.short,
      'long' => _strings.long,
      _ => _strings.medium,
    };
  }

  IconData _providerIcon() {
    return switch (_provider) {
      'cloud' => Icons.cloud,
      _ => Icons.storage,
    };
  }
}
