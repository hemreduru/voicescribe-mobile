import React, { useEffect, useState, useCallback, useRef } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  TextInput,
  PermissionsAndroid,
  Alert,
  Platform,
} from 'react-native';
import { colors, fontSize, spacing } from '../../../../shared/theme';
import { VoiceScribeAudio } from '../../../../native/audio/NativeAudioModule';
import { useRecordingStore, useTranscriptStore } from '../../../../shared/stores';
import type { Transcript } from '../../../../shared/types';

// Dynamic chunking config
const MAX_CHUNK_DURATION_SECONDS = 20;

export const RecordingScreen: React.FC = () => {
  const isRecording = useRecordingStore((state) => state.isRecording);
  const chunkCount = useRecordingStore((state) => state.chunkCount);
  const [sessionTitleInput, setSessionTitleInput] = useState('');
  const [audioLevel, setAudioLevel] = useState(0);
  const [liveTranscriptPreview, setLiveTranscriptPreview] = useState('');
  const [transcriptionError, setTranscriptionError] = useState<string | null>(null);
  const [isModelLoaded, setIsModelLoaded] = useState(false);
  const [recordingDuration, setRecordingDuration] = useState(0);
  const lastRecordingTranscriptIdRef = useRef<string | null>(null);
  const isStoppingRef = useRef(false);
  const stopGuardTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const addTranscript = useTranscriptStore((state) => state.addTranscript);
  const setCurrentTranscript = useTranscriptStore((state) => state.setCurrentTranscript);
  const setCurrentChunks = useTranscriptStore((state) => state.setCurrentChunks);
  const appendChunk = useTranscriptStore((state) => state.appendChunk);
  const updateChunkTextByAudioPath = useTranscriptStore(
    (state) => state.updateChunkTextByAudioPath,
  );
  const updateTranscript = useTranscriptStore((state) => state.updateTranscript);

  const createSessionTranscript = useCallback((manualTitle?: string): Transcript => {
    const now = new Date();
    const id = `local-${now.getTime()}`;
    const isoNow = now.toISOString();
    const normalizedTitle = manualTitle?.trim();
    const defaultTitle = now.toLocaleString();

    return {
      id,
      localId: id,
      title: normalizedTitle && normalizedTitle.length > 0 ? normalizedTitle : defaultTitle,
      durationSeconds: 0,
      statusKey: 'recording',
      recordedAt: isoNow,
      createdAt: isoNow,
      updatedAt: isoNow,
    };
  }, []);

  // Audio chunk handling
  useEffect(() => {
    const chunkSubscription = VoiceScribeAudio.onChunkReady(({ path }) => {
      try {
        const recordingState = useRecordingStore.getState();
        const transcriptId =
          recordingState.currentTranscriptId ?? lastRecordingTranscriptIdRef.current;
        if (!transcriptId) {
          // Ignore orphan chunk events instead of implicitly starting a new recording session.
          return;
        }

        const nextChunkIndex = recordingState.chunkCount + 1;
        const nowIso = new Date().toISOString();

        appendChunk({
          id: `${transcriptId}-chunk-${nextChunkIndex}`,
          transcriptId,
          chunkIndex: nextChunkIndex,
          text: '',
          audioPath: path,
          recordedAt: nowIso,
          startTime: (nextChunkIndex - 1) * MAX_CHUNK_DURATION_SECONDS,
          endTime: nextChunkIndex * MAX_CHUNK_DURATION_SECONDS,
          speakerLabel: null,
          confidence: null,
        });

        if (recordingState.isRecording) {
          useRecordingStore.getState().incrementChunkCount();
        }
        updateTranscript(transcriptId, {
          updatedAt: nowIso,
          statusKey: 'transcribing',
          durationSeconds: nextChunkIndex * MAX_CHUNK_DURATION_SECONDS,
        });
      } catch (err) {
        console.warn('Chunk handling error:', err);
      }
    });

    const transcriptSubscription = VoiceScribeAudio.onTranscriptReady(({ chunkPath, text }) => {
      try {
        const normalizedText = text?.trim() || '';
        if (normalizedText.length > 0) {
          setTranscriptionError(null);
          updateChunkTextByAudioPath(chunkPath, normalizedText);
          const matchedChunk = useTranscriptStore
            .getState()
            .allChunks.find((chunk) => chunk.audioPath === chunkPath);
          if (matchedChunk?.transcriptId) {
            updateTranscript(matchedChunk.transcriptId, {
              updatedAt: new Date().toISOString(),
              statusKey: 'completed',
            });
            if (matchedChunk.transcriptId === lastRecordingTranscriptIdRef.current) {
              isStoppingRef.current = false;
            }
          }
          setLiveTranscriptPreview((prev) => {
            const merged = `${prev} ${normalizedText}`.replace(/\s+/g, ' ').trim();
            return merged.length > 500 ? merged.slice(-500) : merged;
          });
        }
      } catch (err) {
        console.warn('Transcript handling error:', err);
      }
    });

    const errorSubscription = VoiceScribeAudio.onTranscriptionError(({ message }) => {
      setTranscriptionError(message);
      const fallbackId =
        useRecordingStore.getState().currentTranscriptId ?? lastRecordingTranscriptIdRef.current;
      if (fallbackId) {
        updateTranscript(fallbackId, {
          updatedAt: new Date().toISOString(),
          statusKey: 'transcription_error',
        });
      }
    });

    VoiceScribeAudio.isWhisperModelLoaded()
      .then(setIsModelLoaded)
      .catch(() => setIsModelLoaded(false));

    return () => {
      if (stopGuardTimerRef.current) {
        clearTimeout(stopGuardTimerRef.current);
      }
      chunkSubscription.remove();
      transcriptSubscription.remove();
      errorSubscription.remove();
    };
  }, [
    addTranscript,
    appendChunk,
    setCurrentChunks,
    setCurrentTranscript,
    updateChunkTextByAudioPath,
    updateTranscript,
    createSessionTranscript,
  ]);

  // Audio level handling - direct update without decay
  useEffect(() => {
    const levelSubscription = VoiceScribeAudio.onAudioLevel(({ level }) => {
      setAudioLevel(Math.max(0, Math.min(level, 1)));
    });

    return () => {
      levelSubscription.remove();
    };
  }, []);

  // Recording duration timer
  useEffect(() => {
    if (!isRecording) {
      return;
    }

    setRecordingDuration(0);
    const intervalId = setInterval(() => {
      setRecordingDuration((prev) => prev + 1);
    }, 1000);

    return () => {
      clearInterval(intervalId);
    };
  }, [isRecording]);

  const requestMicrophonePermission = async () => {
    if (Platform.OS === 'android') {
      try {
        const granted = await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
          {
            title: 'Microphone Permission',
            message: 'VoiceScribe needs microphone access to record and transcribe.',
            buttonNeutral: 'Ask Later',
            buttonNegative: 'Cancel',
            buttonPositive: 'OK',
          }
        );
        return granted === PermissionsAndroid.RESULTS.GRANTED;
      } catch (err) {
        console.warn(err);
        return false;
      }
    }
    return true;
  };

  const handleToggleRecord = async () => {
    try {
      if (isRecording) {
        // STOP RECORDING
        isStoppingRef.current = true;
        VoiceScribeAudio.stopRecording();
        if (stopGuardTimerRef.current) {
          clearTimeout(stopGuardTimerRef.current);
        }
        stopGuardTimerRef.current = setTimeout(() => {
          isStoppingRef.current = false;
        }, 3000);
        
        const recordingState = useRecordingStore.getState();
        const transcriptId = recordingState.currentTranscriptId;
        const finalChunkCount = recordingState.chunkCount;
        lastRecordingTranscriptIdRef.current = transcriptId;

        // Update store first
        useRecordingStore.getState().stopRecording();

        // Then update transcript if exists
        if (transcriptId) {
          updateTranscript(transcriptId, {
            updatedAt: new Date().toISOString(),
            statusKey: finalChunkCount > 0 ? 'transcribing' : 'empty',
            durationSeconds: recordingDuration,
          });
        }
      } else {
        // START RECORDING
        if (isStoppingRef.current) {
          // Prevent accidental immediate restart while previous session is still flushing.
          return;
        }
        const hasPermission = await requestMicrophonePermission();
        if (!hasPermission) {
          Alert.alert('Permission Denied', 'Microphone permission is required.');
          return;
        }

        // Reset state
        setLiveTranscriptPreview('');
        setTranscriptionError(null);
        setAudioLevel(0);
        setRecordingDuration(0);

        // Create transcript
        const transcript = createSessionTranscript(sessionTitleInput);
        addTranscript(transcript);
        setCurrentTranscript(transcript);
        setCurrentChunks([]);
        
        // Start recording in store
        useRecordingStore.getState().startRecording(transcript.id);
        lastRecordingTranscriptIdRef.current = transcript.id;
        
        // Start native recording
        VoiceScribeAudio.startRecording();
        
        // Clear input
        setSessionTitleInput('');
      }
    } catch (error) {
      console.error('Recording toggle error:', error);
      useRecordingStore.getState().stopRecording();
      Alert.alert('Error', String(error));
    }
  };

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  // Simple line visualization based on audio level
  const lineWidth = Math.max(2, audioLevel * 100);

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.icon}>🎙️</Text>
        <Text style={styles.title}>Recording</Text>
        
        {!isRecording && (
          <TextInput
            value={sessionTitleInput}
            onChangeText={setSessionTitleInput}
            placeholder="Session name (optional)"
            placeholderTextColor={colors.textMuted}
            style={styles.sessionInput}
          />
        )}

        {/* Audio Level - Simple Line */}
        <View style={styles.audioLevelContainer}>
          <View style={styles.audioLevelTrack}>
            <View style={[styles.audioLevelFill, { width: `${lineWidth}%` }]} />
          </View>
          <Text style={styles.audioLevelText}>
            {isRecording ? `${Math.round(audioLevel * 100)}%` : 'Ready'}
          </Text>
        </View>

        {/* Record Button */}
        <TouchableOpacity 
          style={[styles.recordButton, isRecording && styles.recordButtonActive]} 
          onPress={handleToggleRecord}
        >
          <View style={[styles.recordButtonInner, isRecording && styles.recordButtonInnerActive]} />
        </TouchableOpacity>
        
        {/* Status */}
        <Text style={styles.statusText}>
          {isRecording 
            ? `Recording: ${formatDuration(recordingDuration)} • Chunks: ${chunkCount}`
            : 'Tap to start recording'}
        </Text>

        {/* Live Transcript Preview */}
        {isRecording && (
          <View style={styles.transcriptPreview}>
            <Text style={styles.previewLabel}>Live Transcript</Text>
            <Text style={styles.previewText} numberOfLines={5}>
              {liveTranscriptPreview || 'Listening... speak clearly.'}
            </Text>
          </View>
        )}

        {/* Error Display */}
        {transcriptionError && (
          <Text style={styles.errorText}>Error: {transcriptionError}</Text>
        )}

        {/* Model Status */}
        <Text style={styles.modelStatus}>
          Whisper: {isModelLoaded ? '✅ Ready (Auto-detect language)' : '⏳ Loading...'}
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
  },
  icon: {
    fontSize: 64,
    marginBottom: spacing.md,
  },
  title: {
    fontSize: fontSize.heading,
    fontWeight: '700',
    color: colors.text,
    marginBottom: spacing.lg,
  },
  sessionInput: {
    width: '100%',
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surface,
    color: colors.text,
    borderRadius: 10,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    marginBottom: spacing.lg,
    fontSize: fontSize.md,
  },
  audioLevelContainer: {
    width: '100%',
    marginBottom: spacing.lg,
    alignItems: 'center',
  },
  audioLevelTrack: {
    width: '100%',
    height: 8,
    backgroundColor: colors.surface,
    borderRadius: 4,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: colors.border,
  },
  audioLevelFill: {
    height: '100%',
    backgroundColor: colors.primary,
    borderRadius: 4,
  },
  audioLevelText: {
    marginTop: spacing.xs,
    fontSize: fontSize.sm,
    color: colors.textSecondary,
  },
  recordButton: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.surface,
    borderWidth: 4,
    borderColor: colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  recordButtonActive: {
    borderColor: colors.secondary,
  },
  recordButtonInner: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.secondary,
  },
  recordButtonInnerActive: {
    width: 24,
    height: 24,
    borderRadius: 4,
    backgroundColor: colors.secondary,
  },
  statusText: {
    fontSize: fontSize.md,
    color: colors.textSecondary,
    marginBottom: spacing.md,
  },
  transcriptPreview: {
    width: '100%',
    backgroundColor: colors.surface,
    borderRadius: 10,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: spacing.md,
    maxHeight: 150,
  },
  previewLabel: {
    fontSize: fontSize.xs,
    color: colors.textMuted,
    marginBottom: spacing.xs,
    fontWeight: '600',
  },
  previewText: {
    fontSize: fontSize.sm,
    color: colors.text,
    lineHeight: 20,
  },
  errorText: {
    fontSize: fontSize.sm,
    color: colors.secondary,
    marginBottom: spacing.sm,
  },
  modelStatus: {
    fontSize: fontSize.sm,
    color: colors.textMuted,
    marginTop: spacing.md,
  },
});
