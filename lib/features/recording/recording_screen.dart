import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/utils/text_utils.dart';
import 'package:voicescribe_mobile/shared/widgets/app_card.dart';
import 'package:voicescribe_mobile/shared/widgets/audio_visualizer.dart';
import 'package:voicescribe_mobile/shared/widgets/premium_widgets.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final app = ref.watch(appControllerProvider);
    final theme = Theme.of(context);
    final recent = app.transcripts.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recording)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AppCard(
              showAccent: true,
              accentColor: _statusColor(context, app),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: l10n.recordingStatus,
                    subtitle: app.isRecording
                        ? app.isPaused
                              ? l10n.recordingPaused
                              : l10n.isRecording
                        : l10n.tapToRecord,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusPill(
                        icon: app.modelState == ModelBootstrapState.ready
                            ? Icons.check_circle
                            : Icons.sync,
                        label: app.modelState == ModelBootstrapState.ready
                            ? l10n.modelReady
                            : l10n.modelLoading,
                        color: app.modelState == ModelBootstrapState.ready
                            ? AppTheme.teal
                            : theme.colorScheme.secondary,
                      ),
                      MetricPill(
                        icon: Icons.timer_outlined,
                        value: formatCompactDuration(app.durationSeconds),
                        label: l10n.duration,
                      ),
                      MetricPill(
                        icon: Icons.graphic_eq,
                        value: '${app.chunkCount}',
                        label: l10n.chunks,
                        color: AppTheme.amber,
                      ),
                    ],
                  ),
                  if (!app.isRecording) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: l10n.sessionNamePlaceholder,
                        prefixIcon: const Icon(Icons.edit_note),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 26),
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
            if (app.isRecording) ...[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: app.togglePause,
                    icon: Icon(app.isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(app.isPaused ? l10n.resume : l10n.pause),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: app.stopRecording,
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.stop),
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
                showAccent: true,
                accentColor: theme.colorScheme.secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: l10n.liveTranscript,
                      subtitle: '${app.chunkCount} ${l10n.chunks}',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      app.liveTranscriptPreview,
                      maxLines: 5,
                      overflow: TextOverflow.fade,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
            if (app.lastError != null) ...[
              const SizedBox(height: 12),
              Text(
                app.lastError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            SectionHeader(
              title: l10n.recentRecordings,
              subtitle: recent.isEmpty ? null : '${recent.length} kayıt',
            ),
            const SizedBox(height: 12),
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

  Color _statusColor(BuildContext context, AppController app) {
    if (app.isPaused) {
      return AppTheme.amber;
    }
    if (app.isRecording) {
      return Theme.of(context).colorScheme.error;
    }
    return AppTheme.teal;
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
          shadowColor: (isRecording ? scheme.error : scheme.primary).withValues(
            alpha: 0.32,
          ),
          elevation: 4,
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final recordedAt = transcript.recordedAt ?? transcript.createdAt;
    return AppCard(
      showAccent: true,
      accentColor: theme.colorScheme.secondary,
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
                  transcript.title?.trim().isNotEmpty ?? false
                      ? transcript.title!
                      : l10n.unnamed,
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
