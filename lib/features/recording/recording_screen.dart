import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/utils/text_utils.dart';
import 'package:voicescribe_mobile/shared/widgets/app_button.dart';
import 'package:voicescribe_mobile/shared/widgets/app_card.dart';
import 'package:voicescribe_mobile/shared/widgets/app_page.dart';
import 'package:voicescribe_mobile/shared/widgets/app_text_field.dart';
import 'package:voicescribe_mobile/shared/widgets/audio_visualizer.dart';
import 'package:voicescribe_mobile/shared/widgets/premium_widgets.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  final _titleController = TextEditingController();
  String? _boundTranscriptId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recordingState = ref.watch(
      appControllerProvider.select(
        (app) => (
          transcripts: app.transcripts,
          currentTranscript: app.currentTranscript,
          isRecording: app.isRecording,
          isPaused: app.isPaused,
          durationSeconds: app.durationSeconds,
          lastError: app.lastError,
        ),
      ),
    );
    final app = ref.read(appControllerProvider);
    final theme = Theme.of(context);
    final recent = recordingState.transcripts.take(3).toList();
    _syncTitleController(recordingState.currentTranscript);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recording)),
      body: SafeArea(
        child: AppPageListView(
          children: [
            AppCard(
              child: AppTextField(
                controller: _titleController,
                hintText: l10n.sessionNamePlaceholder,
                prefixIcon: Icons.edit_note,
                textInputAction: TextInputAction.done,
                onChanged: (value) => _updateCurrentTitle(app, value),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < AppLayout.compactWidth;
                  return _RecordButton(
                    isRecording: recordingState.isRecording,
                    dimension: compact ? 154 : 172,
                    semanticLabel: recordingState.isRecording
                        ? l10n.stop
                        : l10n.tapToRecord,
                    onPressed: () => _toggleRecording(app),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppDurationDisplay(
              value: formatDuration(recordingState.durationSeconds),
            ),
            if (recordingState.isRecording) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButtonGroup(
                children: [
                  AppButton(
                    label: recordingState.isPaused ? l10n.resume : l10n.pause,
                    icon: recordingState.isPaused
                        ? Icons.play_arrow
                        : Icons.pause,
                    onPressed: app.togglePause,
                  ),
                  AppButton(
                    label: l10n.stop,
                    icon: Icons.stop,
                    onPressed: app.stopRecording,
                    variant: AppButtonVariant.outline,
                  ),
                ],
              ),
              if (!recordingState.isPaused) ...[
                const SizedBox(height: AppSpacing.xl),
                const _LiveAudioVisualizer(),
              ],
            ],
            if (recordingState.lastError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppErrorText(
                message: recordingState.lastError!,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: l10n.recentRecordings,
              subtitle: recent.isEmpty
                  ? null
                  : l10n.recordingsCount(recent.length),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (recent.isEmpty)
              AppCard(
                child: Text(
                  l10n.noRecordings,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else
              ...recent.map(
                (transcript) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                  child: _RecentTranscriptCard(transcript: transcript),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRecording(AppController app) async {
    if (app.isRecording) {
      await app.stopRecording();
      return;
    }
    try {
      await app.startRecording(_titleController.text);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final l10n = context.l10n;
      final message = error is RecordingPermissionException
          ? l10n.permissionDenied
          : error.toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _syncTitleController(Transcript? transcript) {
    final id = transcript?.id;
    if (_boundTranscriptId == id) {
      return;
    }
    _boundTranscriptId = id;
    if (id == null) {
      return;
    }
    final title = transcript?.title ?? '';
    if (_titleController.text != title) {
      _titleController.text = title;
    }
  }

  void _updateCurrentTitle(AppController app, String value) {
    final transcript = app.currentTranscript;
    if (transcript == null) {
      return;
    }
    ref.read(appControllerProvider).updateTranscriptTitle(transcript.id, value);
  }
}

class _LiveAudioVisualizer extends ConsumerWidget {
  const _LiveAudioVisualizer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(
      appControllerProvider.select((app) => app.audioLevel),
    );
    return RepaintBoundary(child: AudioVisualizer(level: level));
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.isRecording,
    required this.onPressed,
    required this.dimension,
    required this.semanticLabel,
  });

  final bool isRecording;
  final double dimension;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: dimension,
        child: FilledButton(
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: isRecording ? scheme.error : scheme.primary,
            shadowColor: (isRecording ? scheme.error : scheme.primary)
                .withValues(alpha: 0.34),
            elevation: 5,
          ),
          onPressed: onPressed,
          child: Icon(
            isRecording ? Icons.stop : Icons.mic,
            color: scheme.onPrimary,
            size: dimension * 0.32,
          ),
        ),
      ),
    );
  }
}

class _RecentTranscriptCard extends StatelessWidget {
  const _RecentTranscriptCard({required this.transcript});

  final Transcript transcript;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final recordedAt = transcript.recordedAt ?? transcript.createdAt;

    return AppCard(
      child: Row(
        children: [
          const AppIconBadge(icon: Icons.graphic_eq),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transcript.title?.trim().isNotEmpty ?? false
                      ? transcript.title!
                      : l10n.unnamed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DateFormat('d MMMM HH:mm').format(recordedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatDuration(transcript.durationSeconds),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
