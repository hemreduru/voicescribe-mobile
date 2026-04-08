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
  Dimensions,
} from 'react-native';
import { colors, fontSize, spacing, borderRadius } from '../../../../shared/theme';
import { GlassCard } from '../../../../shared/components/GlassCard';
import { VoiceScribeAudio } from '../../../../native/audio/NativeAudioModule';
import { useRecordingStore, useTranscriptStore } from '../../../../shared/stores';
import { removeOverlap } from '../../../../shared/utils/textUtils';
import type { Transcript } from '../../../../shared/types';

// Dynamic chunking config
const MAX_CHUNK_DURATION_SECONDS = 20;

const { width } = Dimensions.get('window');

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
  const updateChunkTextByAudioPath = useTranscriptStore((state) => state.updateChunkTextByAudioPath);
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
        if (recordingState.isRecording) {
          useRecordingStore.getState().incrementChunkCount();
        }
      } catch (err) {
        console.warn('Chunk UI handling error:', err);
      }
    });

    const transcriptSubscription = VoiceScribeAudio.onTranscriptReady(({ chunkPath, text }) => {
      try {
        const normalizedText = text?.trim() || '';
        if (normalizedText.length > 0) {
          setTranscriptionError(null);
          
          let deduplicatedText = normalizedText;
          const store = useTranscriptStore.getState();
          const matchedChunk = store.allChunks.find((chunk) => chunk.audioPath === chunkPath);
          
          if (matchedChunk) {
            const sessionChunks = store.allChunks
              .filter(c => c.transcriptId === matchedChunk.transcriptId)
              .sort((a, b) => a.chunkIndex - b.chunkIndex);
              
            const prevChunk = sessionChunks.find(c => c.chunkIndex === matchedChunk.chunkIndex - 1);
            if (prevChunk && prevChunk.text) {
              deduplicatedText = removeOverlap(prevChunk.text, normalizedText);
            }
          }
          
          if (matchedChunk?.transcriptId && matchedChunk.transcriptId === lastRecordingTranscriptIdRef.current) {
            isStoppingRef.current = false;
          }
          setLiveTranscriptPreview((prev) => {
            const merged = `${prev} ${deduplicatedText}`.replace(/\s+/g, ' ').trim();
            return merged.length > 500 ? merged.slice(-500) : merged;
          });
        }
      } catch (err) {
        console.warn('Transcript UI handling error:', err);
      }
    });

    const errorSubscription = VoiceScribeAudio.onTranscriptionError(({ message }) => {
      setTranscriptionError(message);
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
  }, [addTranscript, appendChunk, setCurrentChunks, setCurrentTranscript, updateChunkTextByAudioPath, updateTranscript, createSessionTranscript]);

  // Audio level handling
  useEffect(() => {
    const levelSubscription = VoiceScribeAudio.onAudioLevel(({ level }) => {
      setAudioLevel(Math.max(0, Math.min(level, 1)));
    });
    return () => levelSubscription.remove();
  }, []);

  // Timer
  useEffect(() => {
    if (!isRecording) return;
    setRecordingDuration(0);
    const intervalId = setInterval(() => {
      setRecordingDuration((prev) => prev + 1);
    }, 1000);
    return () => clearInterval(intervalId);
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
        return false;
      }
    }
    return true;
  };

  const handleToggleRecord = async () => {
    try {
      if (isRecording) {
        isStoppingRef.current = true;
        VoiceScribeAudio.stopRecording();
        if (stopGuardTimerRef.current) clearTimeout(stopGuardTimerRef.current);
        stopGuardTimerRef.current = setTimeout(() => { isStoppingRef.current = false; }, 3000);
        
        const recordingState = useRecordingStore.getState();
        const transcriptId = recordingState.currentTranscriptId;
        const finalChunkCount = recordingState.chunkCount;
        lastRecordingTranscriptIdRef.current = transcriptId;

        useRecordingStore.getState().stopRecording();

        if (transcriptId) {
          updateTranscript(transcriptId, {
            updatedAt: new Date().toISOString(),
            statusKey: finalChunkCount > 0 ? 'transcribing' : 'empty',
            durationSeconds: recordingDuration,
          });
        }
      } else {
        if (isStoppingRef.current) return;
        const hasPermission = await requestMicrophonePermission();
        if (!hasPermission) {
          Alert.alert('Permission Denied', 'Microphone permission is required.');
          return;
        }

        setLiveTranscriptPreview('');
        setTranscriptionError(null);
        setAudioLevel(0);
        setRecordingDuration(0);

        const transcript = createSessionTranscript(sessionTitleInput);
        addTranscript(transcript);
        setCurrentTranscript(transcript);
        setCurrentChunks([]);
        
        useRecordingStore.getState().startRecording(transcript.id);
        lastRecordingTranscriptIdRef.current = transcript.id;
        VoiceScribeAudio.startRecording();
        setSessionTitleInput('');
      }
    } catch (error) {
      useRecordingStore.getState().stopRecording();
      Alert.alert('Error', String(error));
    }
  };

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const currentGlowScale = isRecording ? 1 + (audioLevel * 0.4) : 1;

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>VoiceScribe</Text>
        <Text style={styles.subtitle}>
          {isModelLoaded ? 'AI Ready' : 'Loading Model...'}
        </Text>
      </View>

      <View style={styles.centerStage}>
        {/* Breathing background glow layer */}
        <View style={[
          styles.glowRing, 
          { 
            transform: [{ scale: currentGlowScale }],
            opacity: isRecording ? 0.6 : 0 
          }
        ]} />

        {/* The large glass record button */}
        <TouchableOpacity 
          style={styles.recordButtonOuter}
          activeOpacity={0.8}
          onPress={handleToggleRecord}
        >
          <View style={[
            styles.recordButtonInner, 
            isRecording && styles.recordButtonActive
          ]}>
            {isRecording ? (
              <View style={styles.stopSquare} />
            ) : (
              <Text style={styles.micIcon}>🎙️</Text>
            )}
          </View>
        </TouchableOpacity>
      </View>

      <View style={styles.bottomSection}>
        {isRecording ? (
          <GlassCard intensity="high" padding="lg" style={styles.activePill}>
            <Text style={styles.timerText}>{formatDuration(recordingDuration)}</Text>
            <View style={styles.divider} />
            <Text style={styles.chunkText}>Ch. {chunkCount}</Text>
          </GlassCard>
        ) : (
          <GlassCard intensity="low" padding="md" style={styles.inputContainer}>
            <TextInput
              value={sessionTitleInput}
              onChangeText={setSessionTitleInput}
              placeholder="Name this session..."
              placeholderTextColor={colors.textMuted}
              style={styles.sessionInput}
            />
          </GlassCard>
        )}

        {/* Live Transcript Preview */}
        {isRecording && liveTranscriptPreview.length > 0 && (
          <GlassCard intensity="low" padding="lg" style={styles.previewContainer}>
            <Text style={styles.previewText} numberOfLines={3}>
              {liveTranscriptPreview}
              <Text style={styles.cursor}>_</Text>
            </Text>
          </GlassCard>
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  header: {
    paddingTop: 60,
    paddingHorizontal: spacing.lg,
    alignItems: 'center',
  },
  title: {
    fontFamily: 'sans-serif-medium',
    fontSize: fontSize.xxl,
    fontWeight: '700',
    color: colors.text,
    letterSpacing: -0.5,
  },
  subtitle: {
    fontFamily: 'sans-serif',
    fontSize: fontSize.sm,
    color: colors.success,
    marginTop: spacing.xs,
  },
  centerStage: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  glowRing: {
    position: 'absolute',
    width: 280,
    height: 280,
    borderRadius: 140,
    backgroundColor: colors.glowPrimary,
  },
  recordButtonOuter: {
    width: 140,
    height: 140,
    borderRadius: 70,
    backgroundColor: 'rgba(55, 73, 173, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
  },
  recordButtonInner: {
    width: 110,
    height: 110,
    borderRadius: 55,
    backgroundColor: colors.primaryContainer,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: colors.primary,
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.5,
    shadowRadius: 20,
    elevation: 10,
  },
  recordButtonActive: {
    backgroundColor: colors.secondaryContainer,
    shadowColor: colors.secondary,
  },
  stopSquare: {
    width: 32,
    height: 32,
    backgroundColor: colors.white,
    borderRadius: 6,
  },
  micIcon: {
    fontSize: 48,
    color: colors.white,
  },
  bottomSection: {
    paddingHorizontal: spacing.lg,
    paddingBottom: 120, // Offset for bottom tab
    alignItems: 'center',
  },
  activePill: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 40,
    marginBottom: spacing.lg,
  },
  timerText: {
    fontFamily: 'sans-serif-medium',
    fontSize: fontSize.xl,
    color: colors.white,
    letterSpacing: 2,
  },
  divider: {
    width: 1,
    height: 20,
    backgroundColor: colors.divider,
    marginHorizontal: spacing.lg,
  },
  chunkText: {
    fontFamily: 'sans-serif',
    fontSize: fontSize.md,
    color: colors.textSecondary,
  },
  inputContainer: {
    width: '100%',
    borderRadius: borderRadius.lg,
  },
  sessionInput: {
    fontFamily: 'sans-serif',
    fontSize: fontSize.md,
    color: colors.text,
  },
  previewContainer: {
    width: '100%',
    maxHeight: 120,
  },
  previewText: {
    fontFamily: 'sans-serif',
    fontSize: fontSize.md,
    color: colors.textSecondary,
    lineHeight: 24,
  },
  cursor: {
    color: colors.primary,
  },
});

