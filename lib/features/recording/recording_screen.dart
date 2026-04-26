import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/i18n/app_strings.dart';
import '../../shared/models/domain.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/text_utils.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/audio_visualizer.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  final _titleController = TextEditingController();
  static const _strings = AppStrings();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final theme = Theme.of(context);
    final recent = app.transcripts.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: Text(_strings.recording)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (!app.isRecording)
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: _strings.sessionNamePlaceholder,
                  prefixIcon: const Icon(Icons.edit_note),
                ),
              ),
            const SizedBox(height: 28),
            Center(
              child: _RecordButton(
                isRecording: app.isRecording,
                onPressed: () => _toggleRecording(app),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  formatDuration(app.durationSeconds),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              app.isRecording
                  ? app.isPaused
                        ? _strings.recordingPaused
                        : _strings.isRecording
                  : _strings.tapToRecord,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (app.isRecording) ...[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: app.togglePause,
                    icon: Icon(app.isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(
                      app.isPaused ? _strings.resume : _strings.pause,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: app.stopRecording,
                    icon: const Icon(Icons.stop),
                    label: Text(_strings.stop),
                  ),
                ],
              ),
              if (!app.isPaused) ...[
                const SizedBox(height: 22),
                AudioVisualizer(level: app.audioLevel),
              ],
            ],
            if (app.liveTranscriptPreview.isNotEmpty) ...[
              const SizedBox(height: 20),
              AppCard(
                child: Text(
                  app.liveTranscriptPreview,
                  maxLines: 5,
                  overflow: TextOverflow.fade,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Center(
              child: Chip(
                avatar: Icon(
                  app.modelState == ModelBootstrapState.ready
                      ? Icons.check_circle
                      : Icons.sync,
                  size: 18,
                ),
                label: Text(
                  app.modelState == ModelBootstrapState.ready
                      ? _strings.modelReady
                      : _strings.modelLoading,
                ),
              ),
            ),
            if (app.lastError != null) ...[
              const SizedBox(height: 12),
              Text(
                app.lastError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _strings.recentRecordings,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _strings.viewAll,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              AppCard(
                child: Text(
                  _strings.noRecordings,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else
              ...recent.map(
                (transcript) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
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
      _titleController.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.isRecording, required this.onPressed});

  final bool isRecording;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 158,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: isRecording ? scheme.error : scheme.primary,
        ),
        onPressed: onPressed,
        child: Icon(
          isRecording ? Icons.stop : Icons.mic,
          color: scheme.onPrimary,
          size: 52,
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
    final theme = Theme.of(context);
    final recordedAt = transcript.recordedAt ?? transcript.createdAt;
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.graphic_eq, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transcript.title?.trim().isNotEmpty == true
                      ? transcript.title!
                      : const AppStrings().unnamed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
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
