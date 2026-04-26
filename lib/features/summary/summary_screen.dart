import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/i18n/app_strings.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/widgets/app_card.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_strings.summary)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
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
              onSelectionChanged: (value) =>
                  setState(() => _provider = value.first),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'short', label: Text(_strings.short)),
                ButtonSegment(value: 'medium', label: Text(_strings.medium)),
                ButtonSegment(value: 'long', label: Text(_strings.long)),
              ],
              selected: {_length},
              onSelectionChanged: (value) =>
                  setState(() => _length = value.first),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latestTranscript?.title ?? _strings.summary,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    latestText.isEmpty
                        ? _strings.summaryPlaceholder
                        : 'Hazır transkript seçildi. $_provider / $_length özetleme motoru bağlanınca bu metin üzerinden üretim yapılacak.',
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
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
}
