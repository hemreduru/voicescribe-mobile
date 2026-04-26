import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/i18n/app_strings.dart';
import '../../shared/models/domain.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/widgets/app_card.dart';

class SpeakerScreen extends ConsumerStatefulWidget {
  const SpeakerScreen({super.key});

  @override
  ConsumerState<SpeakerScreen> createState() => _SpeakerScreenState();
}

class _SpeakerScreenState extends ConsumerState<SpeakerScreen> {
  static const _strings = AppStrings();
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_strings.speaker)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSpeakerDialog(context, app),
        icon: const Icon(Icons.person_add),
        label: Text(_strings.addNewSpeaker),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            AppCard(
              backgroundColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.42,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _strings.speakerRecognition,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Switch(
                        value: _enabled,
                        onChanged: (value) => setState(() => _enabled = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _strings.speakerRecognitionDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${_strings.registeredSpeakers} (${app.speakers.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (app.speakers.isEmpty)
              EmptyState(
                icon: Icons.group_outlined,
                title: _strings.speaker,
                description: _strings.speakerRecognitionDesc,
              )
            else
              ...app.speakers.map(
                (speaker) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SpeakerCard(
                    speaker: speaker,
                    onEdit: () =>
                        _showSpeakerDialog(context, app, speaker: speaker),
                    onDelete: () => app.deleteSpeaker(speaker.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSpeakerDialog(
    BuildContext context,
    AppController app, {
    SpeakerProfile? speaker,
  }) {
    final controller = TextEditingController(text: speaker?.name ?? '');
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(speaker == null ? _strings.addNewSpeaker : _strings.edit),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Konuşmacı adı'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (speaker == null) {
                  app.addSpeaker(controller.text);
                } else {
                  app.updateSpeaker(speaker.id, controller.text);
                }
                Navigator.pop(context);
              },
              child: Text(
                speaker == null ? _strings.addNewSpeaker : _strings.edit,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SpeakerCard extends StatelessWidget {
  const _SpeakerCard({
    required this.speaker,
    required this.onEdit,
    required this.onDelete,
  });

  final SpeakerProfile speaker;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _colorFor(speaker.id),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speaker.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${speaker.recordings} ${const AppStrings().recording}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(
                speaker.hasVoiceSample ? Icons.mic : Icons.mic_none,
                size: 18,
                color: speaker.hasVoiceSample
                    ? Colors.green
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                speaker.hasVoiceSample
                    ? const AppStrings().voiceSampleAvailable
                    : const AppStrings().recordVoiceSample,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorFor(String id) {
    final colors = [
      Colors.blue,
      Colors.pink,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    final hash = id.codeUnits.fold<int>(0, (value, code) => value + code);
    return colors[hash % colors.length];
  }
}
