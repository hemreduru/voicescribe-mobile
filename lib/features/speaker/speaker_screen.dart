import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/widgets/app_card.dart';
import 'package:voicescribe_mobile/shared/widgets/premium_widgets.dart';

class SpeakerScreen extends ConsumerStatefulWidget {
  const SpeakerScreen({super.key});

  @override
  ConsumerState<SpeakerScreen> createState() => _SpeakerScreenState();
}

class _SpeakerScreenState extends ConsumerState<SpeakerScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final app = ref.watch(appControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.speaker)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSpeakerDialog(context, app),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.addNewSpeaker),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            AppCard(
              onTap: () => app.setSpeakerRecognitionEnabled(
                value: !app.speakerRecognitionEnabled,
              ),
              selected: app.speakerRecognitionEnabled,
              showAccent: true,
              accentColor: app.speakerRecognitionEnabled
                  ? AppTheme.teal
                  : AppTheme.amber,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color:
                              (app.speakerRecognitionEnabled
                                      ? AppTheme.teal
                                      : AppTheme.amber)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.record_voice_over,
                          color: app.speakerRecognitionEnabled
                              ? AppTheme.teal
                              : AppTheme.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.speakerRecognition,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      StatusPill(
                        compact: true,
                        icon: app.speakerRecognitionEnabled
                            ? Icons.check_circle
                            : Icons.pause,
                        label: app.speakerRecognitionEnabled
                            ? l10n.active
                            : l10n.disabled,
                        color: app.speakerRecognitionEnabled
                            ? AppTheme.teal
                            : AppTheme.amber,
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: app.speakerRecognitionEnabled,
                        onChanged: (value) =>
                            app.setSpeakerRecognitionEnabled(value: value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.speakerRecognitionDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: l10n.registeredSpeakers,
              subtitle: '${app.speakers.length} profil',
            ),
            const SizedBox(height: 12),
            if (app.speakers.isEmpty)
              EmptyState(
                icon: Icons.group_outlined,
                title: l10n.speaker,
                description: l10n.speakerRecognitionDesc,
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
          title: Text(
            speaker == null ? context.l10n.addNewSpeaker : context.l10n.edit,
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.l10n.speakerNameLabel,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
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
                speaker == null
                    ? context.l10n.addNewSpeaker
                    : context.l10n.edit,
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
    final l10n = context.l10n;
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
                      '${speaker.recordings} ${l10n.recording}',
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
                tooltip: l10n.edit,
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.delete,
              ),
            ],
          ),
          const PremiumDivider(),
          ActionRow(
            icon: speaker.hasVoiceSample ? Icons.mic : Icons.mic_none,
            title: speaker.hasVoiceSample
                ? l10n.voiceSampleAvailable
                : l10n.recordVoiceSample,
            subtitle: speaker.hasVoiceSample
                ? l10n.profileReadyForRecognition
                : l10n.addSampleLater,
            trailing: StatusPill(
              compact: true,
              icon: speaker.hasVoiceSample ? Icons.check_circle : Icons.add,
              label: speaker.hasVoiceSample ? l10n.ready : l10n.pending,
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
