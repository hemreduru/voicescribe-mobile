import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/i18n/app_strings.dart';
import '../../shared/models/domain.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/premium_widgets.dart';

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
              onTap: () => setState(() => _enabled = !_enabled),
              selected: _enabled,
              showAccent: true,
              accentColor: _enabled ? AppTheme.teal : AppTheme.amber,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (_enabled ? AppTheme.teal : AppTheme.amber)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.record_voice_over,
                          color: _enabled ? AppTheme.teal : AppTheme.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _strings.speakerRecognition,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      StatusPill(
                        compact: true,
                        icon: _enabled ? Icons.check_circle : Icons.pause,
                        label: _enabled ? 'Aktif' : 'Kapalı',
                        color: _enabled ? AppTheme.teal : AppTheme.amber,
                      ),
                      const SizedBox(width: 8),
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
            SectionHeader(
              title: _strings.registeredSpeakers,
              subtitle: '${app.speakers.length} profil',
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
      showAccent: true,
      accentColor: _colorFor(speaker.id),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              IconButton.filledTonal(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                tooltip: const AppStrings().edit,
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: const AppStrings().delete,
              ),
            ],
          ),
          const PremiumDivider(),
          ActionRow(
            icon: speaker.hasVoiceSample ? Icons.mic : Icons.mic_none,
            title: speaker.hasVoiceSample
                ? const AppStrings().voiceSampleAvailable
                : const AppStrings().recordVoiceSample,
            subtitle: speaker.hasVoiceSample
                ? 'Profil tanıma için hazır'
                : 'Daha sonra örnek kayıt eklenebilir',
            trailing: StatusPill(
              compact: true,
              icon: speaker.hasVoiceSample ? Icons.check_circle : Icons.add,
              label: speaker.hasVoiceSample ? 'Hazır' : 'Bekliyor',
              color: speaker.hasVoiceSample ? AppTheme.teal : AppTheme.amber,
            ),
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
