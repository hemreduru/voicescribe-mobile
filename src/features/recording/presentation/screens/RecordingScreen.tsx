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
  ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  withSequence,
  Easing,
  cancelAnimation,
} from 'react-native-reanimated';
import { Mic, Pause, Square, Clock, Activity, Settings, Play } from 'lucide-react-native';
import { useColors } from '../../../../shared/theme';
import { GlassCard } from '../../../../shared/components/GlassCard';
import { AudioVisualizer } from '../../../../shared/components/AudioVisualizer';
import { VoiceScribeAudio } from '../../../../native/audio/NativeAudioModule';
import { useRecordingStore, useTranscriptStore } from '../../../../shared/stores';
import { removeOverlap } from '../../../../shared/utils/textUtils';
import type { Transcript } from '../../../../shared/types';
import { borderRadius, spacing, fontSize, fontWeight } from '../../../../shared/theme/tokens';

// Dynamic chunking config
const MAX_CHUNK_DURATION_SECONDS = 20;

export const RecordingScreen: React.FC = () => {
  const colors = useColors();
  
  const isRecording = useRecordingStore((state) => state.isRecording);
  const isPaused = useRecordingStore((state) => state.isPaused);
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

  // Animation values for pulsing record button
  const pulseScale = useSharedValue(1);
  const pulseOpacity = useSharedValue(0.6);

  // Get recent transcripts (last 3)
  const transcripts = useTranscriptStore((state) => state.transcripts);
  const recentTranscripts = transcripts.slice(0, 3);

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

  // Pulsing animation when recording
  useEffect(() => {
    if (isRecording && !isPaused) {
      pulseScale.value = withRepeat(
        withSequence(
          withTiming(1.15, { duration: 800, easing: Easing.inOut(Easing.ease) }),
          withTiming(1, { duration: 800, easing: Easing.inOut(Easing.ease) })
        ),
        -1,
        false
      );
      pulseOpacity.value = withRepeat(
        withSequence(
          withTiming(0.3, { duration: 800, easing: Easing.inOut(Easing.ease) }),
          withTiming(0.6, { duration: 800, easing: Easing.inOut(Easing.ease) })
        ),
        -1,
        false
      );
    } else {
      cancelAnimation(pulseScale);
      cancelAnimation(pulseOpacity);
      pulseScale.value = withTiming(1, { duration: 300 });
      pulseOpacity.value = withTiming(isRecording ? 0.4 : 0, { duration: 300 });
    }
  }, [isRecording, isPaused, pulseScale, pulseOpacity]);

  const pulseAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: pulseScale.value }],
    opacity: pulseOpacity.value,
  }));

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

  const handlePauseResume = () => {
    if (isPaused) {
      useRecordingStore.getState().resumeRecording();
      VoiceScribeAudio.startRecording();
    } else {
      useRecordingStore.getState().pauseRecording();
      VoiceScribeAudio.stopRecording();
    }
  };

  const handleStop = () => {
    handleToggleRecord();
  };

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const formatTranscriptDate = (isoString: string | null) => {
    if (!isoString) return '';
    const date = new Date(isoString);
    return date.toLocaleDateString('tr-TR', { day: 'numeric', month: 'long' });
  };

  const formatTranscriptTime = (isoString: string | null) => {
    if (!isoString) return '';
    const date = new Date(isoString);
    return date.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
  };

  const getStatusText = () => {
    if (isRecording) {
      return isPaused ? 'Kayıt duraklatıldı' : 'Kaydediliyor';
    }
    return 'Kayıt başlatmak için butona tıklayın';
  };

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]}>
      <ScrollView 
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <Text style={[styles.title, { color: colors.text }]}>Kayıt</Text>
          <TouchableOpacity 
            style={[styles.settingsButton, { backgroundColor: colors.surfaceSecondary }]}
            onPress={() => {}}
          >
            <Settings size={24} color={colors.textSecondary} />
          </TouchableOpacity>
        </View>

        {/* Center Stage - Record Button */}
        <View style={styles.centerStage}>
          {/* Pulsing ring animation */}
          <Animated.View 
            style={[
              styles.pulseRing,
              { backgroundColor: isRecording ? colors.error : colors.primary },
              pulseAnimatedStyle
            ]} 
          />

          {/* Large circular record button */}
          <TouchableOpacity 
            style={[
              styles.recordButton,
              { 
                backgroundColor: isRecording ? colors.error : colors.primary,
                borderColor: isRecording ? colors.error : colors.primary,
              }
            ]}
            activeOpacity={0.8}
            onPress={handleToggleRecord}
          >
            {isRecording ? (
              <Square size={40} color={colors.white} fill={colors.white} />
            ) : (
              <Mic size={48} color={colors.white} />
            )}
          </TouchableOpacity>
        </View>

        {/* Timer Display */}
        <View style={styles.timerContainer}>
          <Clock size={28} color={colors.textSecondary} />
          <Text style={[styles.timerText, { color: colors.text }]}>
            {formatDuration(recordingDuration)}
          </Text>
        </View>

        {/* Status Text */}
        <Text style={[styles.statusText, { color: colors.textSecondary }]}>
          {getStatusText()}
        </Text>

        {/* Control Buttons (when recording) */}
        {isRecording && (
          <View style={styles.controlButtons}>
            <TouchableOpacity
              style={[
                styles.controlButton,
                { backgroundColor: isPaused ? colors.success : colors.warning }
              ]}
              onPress={handlePauseResume}
            >
              {isPaused ? (
                <Play size={20} color={colors.white} fill={colors.white} />
              ) : (
                <Pause size={20} color={colors.white} fill={colors.white} />
              )}
              <Text style={styles.controlButtonText}>
                {isPaused ? 'Devam Et' : 'Duraklat'}
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[
                styles.controlButton,
                { backgroundColor: colors.surface }
              ]}
              onPress={handleStop}
            >
              <Square size={20} color={colors.white} fill={colors.white} />
              <Text style={styles.controlButtonText}>Durdur</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Audio Visualizer (when recording) */}
        {isRecording && !isPaused && (
          <View style={styles.visualizerContainer}>
            <AudioVisualizer isActive={isRecording && !isPaused} barCount={20} />
          </View>
        )}

        {/* Session Title Input (when not recording) */}
        {!isRecording && (
          <View style={styles.inputSection}>
            <GlassCard intensity="low" padding="md">
              <TextInput
                value={sessionTitleInput}
                onChangeText={setSessionTitleInput}
                placeholder="Oturum adı girin..."
                placeholderTextColor={colors.textMuted}
                style={[styles.sessionInput, { color: colors.text }]}
              />
            </GlassCard>
          </View>
        )}

        {/* Live Transcript Preview (when recording) */}
        {isRecording && liveTranscriptPreview.length > 0 && (
          <View style={styles.previewSection}>
            <GlassCard intensity="low" padding="lg">
              <Text 
                style={[styles.previewText, { color: colors.textSecondary }]} 
                numberOfLines={4}
              >
                {liveTranscriptPreview}
                <Text style={[styles.cursor, { color: colors.primary }]}>_</Text>
              </Text>
            </GlassCard>
          </View>
        )}

        {/* Transcription Error */}
        {transcriptionError && (
          <View style={styles.errorContainer}>
            <Text style={[styles.errorText, { color: colors.error }]}>
              {transcriptionError}
            </Text>
          </View>
        )}

        {/* Model Status */}
        <View style={styles.modelStatus}>
          <Text style={[styles.modelStatusText, { color: isModelLoaded ? colors.success : colors.textMuted }]}>
            {isModelLoaded ? 'AI Hazır' : 'Model yükleniyor...'}
          </Text>
        </View>

        {/* Recent Recordings Section */}
        <View style={styles.recentSection}>
          <View style={styles.recentHeader}>
            <Text style={[styles.recentTitle, { color: colors.text }]}>Son Kayıtlar</Text>
            <TouchableOpacity onPress={() => {}}>
              <Text style={[styles.viewAllText, { color: colors.primary }]}>Tümünü Gör</Text>
            </TouchableOpacity>
          </View>

          {recentTranscripts.length > 0 ? (
            recentTranscripts.map((transcript) => (
              <GlassCard 
                key={transcript.id} 
                intensity="low" 
                padding="md"
                style={styles.recentCard}
              >
                <View style={styles.recentCardContent}>
                  <View style={[styles.recentIconContainer, { backgroundColor: colors.primaryLight }]}>
                    <Activity size={20} color={colors.primary} />
                  </View>
                  <View style={styles.recentCardInfo}>
                    <Text style={[styles.recentCardTitle, { color: colors.text }]}>
                      {transcript.title || 'Adsız Kayıt'}
                    </Text>
                    <Text style={[styles.recentCardMeta, { color: colors.textSecondary }]}>
                      {formatTranscriptDate(transcript.recordedAt)} • {formatTranscriptTime(transcript.recordedAt)}
                    </Text>
                  </View>
                  <Text style={[styles.recentCardDuration, { color: colors.textMuted }]}>
                    {formatDuration(transcript.durationSeconds)}
                  </Text>
                </View>
              </GlassCard>
            ))
          ) : (
            <GlassCard intensity="low" padding="lg" style={styles.emptyCard}>
              <Text style={[styles.emptyText, { color: colors.textMuted }]}>
                Henüz kayıt bulunmuyor
              </Text>
            </GlassCard>
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: spacing.lg,
    paddingBottom: spacing.xxl,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: spacing.md,
    paddingBottom: spacing.lg,
  },
  title: {
    fontSize: fontSize.heading,
    fontWeight: fontWeight.bold,
  },
  settingsButton: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.full,
    justifyContent: 'center',
    alignItems: 'center',
  },
  centerStage: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing.xl,
  },
  pulseRing: {
    position: 'absolute',
    width: 180,
    height: 180,
    borderRadius: 90,
  },
  recordButton: {
    width: 160,
    height: 160,
    borderRadius: 80,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  timerContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    paddingVertical: spacing.md,
  },
  timerText: {
    fontSize: 36,
    fontFamily: 'monospace',
    fontWeight: '600',
    letterSpacing: 2,
  },
  statusText: {
    fontSize: fontSize.md,
    textAlign: 'center',
    paddingVertical: spacing.sm,
  },
  controlButtons: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: spacing.md,
    paddingVertical: spacing.lg,
  },
  controlButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.lg,
    borderRadius: borderRadius.full,
    gap: spacing.sm,
  },
  controlButtonText: {
    color: '#ffffff',
    fontSize: fontSize.md,
    fontWeight: fontWeight.semibold,
  },
  visualizerContainer: {
    paddingVertical: spacing.lg,
  },
  inputSection: {
    paddingVertical: spacing.md,
  },
  sessionInput: {
    fontSize: fontSize.md,
  },
  previewSection: {
    paddingVertical: spacing.md,
  },
  previewText: {
    fontSize: fontSize.md,
    lineHeight: 24,
  },
  cursor: {
    fontSize: fontSize.md,
  },
  errorContainer: {
    paddingVertical: spacing.sm,
  },
  errorText: {
    fontSize: fontSize.sm,
    textAlign: 'center',
  },
  modelStatus: {
    alignItems: 'center',
    paddingVertical: spacing.sm,
  },
  modelStatusText: {
    fontSize: fontSize.sm,
  },
  recentSection: {
    paddingTop: spacing.xl,
  },
  recentHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  recentTitle: {
    fontSize: fontSize.lg,
    fontWeight: fontWeight.semibold,
  },
  viewAllText: {
    fontSize: fontSize.sm,
    fontWeight: fontWeight.medium,
  },
  recentCard: {
    marginBottom: spacing.sm,
  },
  recentCardContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  recentIconContainer: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.full,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  recentCardInfo: {
    flex: 1,
  },
  recentCardTitle: {
    fontSize: fontSize.md,
    fontWeight: fontWeight.medium,
  },
  recentCardMeta: {
    fontSize: fontSize.sm,
    marginTop: 2,
  },
  recentCardDuration: {
    fontSize: fontSize.sm,
  },
  emptyCard: {
    alignItems: 'center',
    paddingVertical: spacing.xl,
  },
  emptyText: {
    fontSize: fontSize.md,
  },
});
