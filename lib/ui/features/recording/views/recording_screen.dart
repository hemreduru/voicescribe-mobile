import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/utils/text_utils.dart';
import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_button.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_card.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_page.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_text_field.dart';
import 'package:voicescribe_mobile/ui/core/widgets/audio_visualizer.dart';
import 'package:voicescribe_mobile/ui/core/widgets/premium_widgets.dart';
import 'package:voicescribe_mobile/ui/features/recording/bloc/recording_bloc.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
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

    return BlocConsumer<RecordingBloc, RecordingState>(
      listenWhen: (previous, current) =>
          previous.userMessage != current.userMessage &&
          current.userMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.userMessage!)));
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final recent = state.transcripts.take(3).toList();
        _syncTitleController(state.currentTranscript);

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
                    onChanged: (value) => context.read<RecordingBloc>().add(
                      RecordingTitleChanged(value),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxWidth < AppLayout.compactWidth;
                      return _RecordButton(
                        isRecording: state.isRecording,
                        dimension: compact ? 154 : 172,
                        semanticLabel: state.isRecording
                            ? l10n.stop
                            : l10n.tapToRecord,
                        onPressed: () => _toggleRecording(context, state),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppDurationDisplay(
                  value: formatDuration(state.durationSeconds),
                ),
                if (state.isRecording) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppButtonGroup(
                    children: [
                      AppButton(
                        label: state.isPaused ? l10n.resume : l10n.pause,
                        icon: state.isPaused ? Icons.play_arrow : Icons.pause,
                        onPressed: () => context.read<RecordingBloc>().add(
                          const RecordingPauseToggled(),
                        ),
                      ),
                      AppButton(
                        label: l10n.stop,
                        icon: Icons.stop,
                        onPressed: () => context.read<RecordingBloc>().add(
                          const RecordingStopped(),
                        ),
                        variant: AppButtonVariant.outline,
                      ),
                    ],
                  ),
                  if (!state.isPaused) ...[
                    const SizedBox(height: AppSpacing.xl),
                    RepaintBoundary(
                      child: AudioVisualizer(level: state.audioLevel),
                    ),
                  ],
                ],
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppErrorText(
                    message: state.errorMessage!,
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
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
      },
    );
  }

  void _toggleRecording(BuildContext context, RecordingState state) {
    final bloc = context.read<RecordingBloc>();
    if (state.isRecording) {
      bloc.add(const RecordingStopped());
    } else {
      bloc.add(RecordingStarted(_titleController.text));
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
