import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/widgets/app_button.dart';
import 'package:voicescribe_mobile/shared/widgets/app_card.dart';
import 'package:voicescribe_mobile/shared/widgets/app_page.dart';
import 'package:voicescribe_mobile/shared/widgets/app_text_field.dart';
import 'package:voicescribe_mobile/shared/widgets/premium_widgets.dart';

class SpeakerScreen extends ConsumerStatefulWidget {
  const SpeakerScreen({super.key});

  @override
  ConsumerState<SpeakerScreen> createState() => _SpeakerScreenState();
}

class _SpeakerScreenState extends ConsumerState<SpeakerScreen> {
  bool _calibrating = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final app = ref.watch(appControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.speaker),
        actions: [
          IconButton(
            onPressed: () async {
              await app.logout();
              if (!context.mounted) {
                return;
              }
              context.go('/auth');
            },
            icon: const Icon(Icons.logout),
            tooltip: app.currentUserEmail ?? l10n.logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSpeakerDialog(context, app),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.addNewSpeaker),
      ),
      body: SafeArea(
        child: AppPageListView(
          padding: const EdgeInsets.only(bottom: 84),
          children: [
            AppCard(
              showAccent: true,
              accentColor: AppTheme.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: const Icon(
                          Icons.record_voice_over,
                          color: AppTheme.teal,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          l10n.speakerRecognition,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StatusPill(
                        compact: true,
                        icon: Icons.check_circle,
                        label: l10n.active,
                        color: AppTheme.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.speakerRecognitionDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.speakerThreshold(
                            app.speakerSimilarityThreshold.toStringAsFixed(3),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      AppButton(
                        label: l10n.calibrate,
                        icon: Icons.tune,
                        onPressed: _calibrating
                            ? null
                            : () => _calibrateThreshold(app),
                        isLoading: _calibrating,
                        variant: AppButtonVariant.tonal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              title: l10n.registeredSpeakers,
              subtitle: l10n.profilesCount(app.speakers.length),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (app.speakers.isEmpty)
              EmptyState(
                icon: Icons.group_outlined,
                title: l10n.speaker,
                description: l10n.speakerRecognitionDesc,
              )
            else
              ...app.speakers.map(
                (speaker) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
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

  Future<void> _calibrateThreshold(AppController app) async {
    setState(() => _calibrating = true);
    try {
      final threshold = await app.calibrateSpeakerThreshold();
      if (!mounted) {
        return;
      }
      final l10n = context.l10n;
      final message = threshold == null
          ? l10n.calibrationSkipped
          : l10n.calibrationCompleted(threshold.toStringAsFixed(3));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.calibrationFailed(error.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _calibrating = false);
      }
    }
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
          content: AppTextField(
            controller: controller,
            autofocus: true,
            labelText: context.l10n.speakerNameLabel,
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.done,
          ),
          actions: [
            AppButton(
              label: context.l10n.cancel,
              onPressed: () => Navigator.pop(context),
              variant: AppButtonVariant.text,
            ),
            AppButton(
              label: speaker == null
                  ? context.l10n.addNewSpeaker
                  : context.l10n.edit,
              onPressed: () {
                if (speaker == null) {
                  app.addSpeaker(controller.text);
                } else {
                  app.updateSpeaker(speaker.id, controller.text);
                }
                Navigator.pop(context);
              },
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speaker.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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
              const SizedBox(width: AppSpacing.sm - 2),
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
    final hash = id.codeUnits.fold<int>(0, (value, code) => value + code);
    return AppColors.speakerPalette[hash % AppColors.speakerPalette.length];
  }
}
