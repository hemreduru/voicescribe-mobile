import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:voicescribe_mobile/data/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/utils/text_utils.dart';
import 'package:voicescribe_mobile/ui/core/i18n/error_messages.dart';
import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/theme/premium_tokens.dart';
import 'package:voicescribe_mobile/ui/core/utils/eta_formatters.dart';
import 'package:voicescribe_mobile/ui/core/widgets/ambient_backdrop.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_button.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_card.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_page.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_segmented_control.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_text_field.dart';
import 'package:voicescribe_mobile/ui/core/widgets/audio_visualizer.dart';
import 'package:voicescribe_mobile/ui/core/widgets/premium_widgets.dart';
import 'package:voicescribe_mobile/ui/core/widgets/pulse_record_button.dart';
import 'package:voicescribe_mobile/ui/features/recording/bloc/recording_bloc.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final _titleController = TextEditingController();
  String? _boundTranscriptId;

  /// Language for the next recording, seeded from the active service value
  /// (the persisted default). Changing it here applies to this session only —
  /// it does not overwrite the saved default in Settings.
  String? _sessionLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sessionLanguage ??=
        context.read<TranscriptionService>().currentTranscriptionLanguage;
  }

  @override
  void initState() {
    super.initState();
    // Ask for the permissions the app needs up front, on first entry to the
    // home screen, so the first tap on record never collides with an in-flight
    // permission dialog. Requests run sequentially (Android refuses concurrent
    // permission requests) and are no-ops when already granted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_requestStartupPermissions());
    });
  }

  Future<void> _requestStartupPermissions() async {
    try {
      await Permission.microphone.request();
      await Permission.notification.request();
    } catch (_) {
      // Platform channel may be unavailable (e.g. in tests); recording still
      // requests the microphone again on demand.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Keep the background-transcription foreground-service notification copy
    // localized (cheap string assignment on the bloc).
    context.read<RecordingBloc>().configureBackgroundNotification(
      title: l10n.appName,
      text: l10n.transcribingNotificationContent,
    );

    return BlocConsumer<RecordingBloc, RecordingState>(
      listenWhen: (previous, current) =>
          (previous.userErrorCode != current.userErrorCode &&
              current.userErrorCode != null) ||
          (previous.userMessage != current.userMessage &&
              current.userMessage != null) ||
          previous.currentTranscript?.id != current.currentTranscript?.id,
      listener: (context, state) {
        final message =
            state.userErrorCode?.localized(context.l10n) ?? state.userMessage;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
        _syncTitleController(state.currentTranscript);
      },
      buildWhen: (previous, current) =>
          previous.isRecording != current.isRecording ||
          previous.isPaused != current.isPaused ||
          previous.durationSeconds != current.durationSeconds ||
          previous.errorMessage != current.errorMessage ||
          previous.userErrorCode != current.userErrorCode ||
          previous.userMessage != current.userMessage ||
          previous.transcripts != current.transcripts ||
          previous.currentTranscript != current.currentTranscript ||
          previous.currentChunks != current.currentChunks,
      builder: (context, state) {
        final recent = state.transcripts.take(3).toList();

        return Scaffold(
          appBar: AppBar(title: Text(l10n.recording)),
          body: AmbientBackdrop(
            child: SafeArea(
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
                  if (!state.isRecording) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SessionLanguageSelector(
                      value: _sessionLanguage ?? 'auto',
                      onChanged: (value) {
                        context.read<TranscriptionService>()
                            .setTranscriptionLanguage(value);
                        setState(() => _sessionLanguage = value);
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact =
                            constraints.maxWidth < AppLayout.compactWidth;
                        return PulseRecordButton(
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
                          onPressed: () {
                            AppHaptics.warning();
                            context.read<RecordingBloc>().add(
                              const RecordingStopped(),
                            );
                          },
                          variant: AppButtonVariant.outline,
                        ),
                      ],
                    ),
                    if (!state.isPaused) ...[
                      const SizedBox(height: AppSpacing.xl),
                      // Rebuild only the visualizer on audio-level changes
                      // (~8/sec) instead of waiting for the once-per-second
                      // duration tick, so the waveform stays fluid. The parent
                      // buildWhen intentionally omits audioLevel to avoid
                      // rebuilding the whole screen.
                      RepaintBoundary(
                        child:
                            BlocSelector<RecordingBloc, RecordingState, double>(
                              selector: (state) => state.audioLevel,
                              builder: (context, level) =>
                                  AudioVisualizer(level: level),
                            ),
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
                  const SizedBox(height: AppSpacing.lg),
                  const _TranscriptionStatusStrip(),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(
                    title: l10n.recentRecordings,
                    subtitle: recent.isEmpty
                        ? null
                        : l10n.recordingsCount(recent.length),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (recent.isEmpty)
                    EmptyState(
                      icon: Icons.mic_none,
                      title: l10n.recentRecordings,
                      description: l10n.noRecordings,
                    )
                  else
                    ...recent.map(
                      (transcript) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm + 2,
                        ),
                        child: _RecentTranscriptCard(transcript: transcript),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleRecording(
    BuildContext context,
    RecordingState state,
  ) async {
    final bloc = context.read<RecordingBloc>();
    // Tactile confirmation is owned by PulseRecordButton (medium on start,
    // warning on stop) so it isn't fired twice here.
    if (state.isRecording) {
      bloc.add(const RecordingStopped());
      return;
    }

    // Request the microphone first and await it, so it never collides with the
    // notification request (Android refuses concurrent permission dialogs).
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (context.mounted) {
        _showMicPermissionDenied(
          context,
          permanentlyDenied: mic.isPermanentlyDenied,
        );
      }
      return;
    }

    if (!context.mounted) {
      return;
    }
    // Notification permission (Android 13+) makes the foreground-service
    // notification visible; recording proceeds regardless of the outcome.
    await Permission.notification.request();
    if (!context.mounted) {
      return;
    }
    // Localize the foreground-service notification before recording starts.
    context.read<RecordingService>().setForegroundNotification(
      title: context.l10n.appName,
      content: context.l10n.recordingNotificationContent,
    );
    bloc.add(RecordingStarted(_titleController.text));
  }

  void _showMicPermissionDenied(
    BuildContext context, {
    required bool permanentlyDenied,
  }) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.permissionDenied),
        action: permanentlyDenied
            ? SnackBarAction(
                label: l10n.openSettings,
                onPressed: openAppSettings,
              )
            : null,
      ),
    );
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

/// Per-session speech-language picker (Auto/TR/EN). Applies to the next
/// recording only via the transcription service; it never overwrites the saved
/// default in Settings.
class _SessionLanguageSelector extends StatelessWidget {
  const _SessionLanguageSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.transcriptionLanguage,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSegmentedControl<String>(
            value: value,
            segments: [
              AppSegment(value: 'auto', label: l10n.automatic),
              AppSegment(value: 'tr', label: l10n.turkish),
              AppSegment(value: 'en', label: l10n.english),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Compact, self-rebuilding strip shown on the home screen while transcription
/// is still draining (during recording and after stop). Surfaces the progress
/// the bloc already computes — chunk count + device-specific ETA — so the user
/// isn't left staring at a screen with nothing visibly happening.
class _TranscriptionStatusStrip extends StatelessWidget {
  const _TranscriptionStatusStrip();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordingBloc, RecordingState>(
      buildWhen: (previous, current) =>
          previous.isTranscribing != current.isTranscribing ||
          previous.transcribedProgressChunks !=
              current.transcribedProgressChunks ||
          previous.totalProgressChunks != current.totalProgressChunks ||
          previous.estimatedTranscriptionRemaining !=
              current.estimatedTranscriptionRemaining,
      builder: (context, state) {
        if (!state.isTranscribing) {
          return const SizedBox.shrink();
        }
        final l10n = context.l10n;
        final theme = Theme.of(context);
        final completed = state.transcribedProgressChunks;
        final total = state.totalProgressChunks;
        final percent = total == 0
            ? null
            : (completed / total).clamp(0.0, 1.0);
        final remaining = state.estimatedTranscriptionRemaining;
        final detail = remaining == null || remaining.inSeconds <= 0
            ? l10n.transcriptionProgressChunks(completed, total)
            : '${l10n.transcriptionProgressChunks(completed, total)} · '
                  '${l10n.etaRemaining(humanizeEtaUnit(l10n, remaining))}';

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.transcribingProgressLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.xs),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
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
