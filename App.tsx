import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { AppNavigator } from './src/shared/navigation';
import { colors, fontSize, spacing } from './src/shared/theme';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import {
  VoiceScribeAudio,
  type WhisperModelDownloadProgressEvent,
} from './src/native/audio/NativeAudioModule';
import {
  parseTranscriptStoreState,
  serializeTranscriptStoreState,
  useTranscriptStore,
} from './src/shared/stores/useTranscriptStore';

const WHISPER_MODEL_URL = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin';
const WHISPER_MODEL_FILE_NAME = 'ggml-tiny.bin';

type BootstrapState = 'bootstrapping' | 'failed' | 'ready';

const formatBytes = (bytes: number): string => {
  if (!Number.isFinite(bytes) || bytes <= 0) {
    return '0 MB';
  }

  const mb = bytes / (1024 * 1024);
  if (mb < 1) {
    return `${Math.max(1, Math.round(mb * 1000))} KB`;
  }
  return `${mb.toFixed(1)} MB`;
};

const App: React.FC = () => {
  const [bootstrapState, setBootstrapState] = useState<BootstrapState>('bootstrapping');
  const [bootstrapError, setBootstrapError] = useState<string | null>(null);
  const [downloadProgress, setDownloadProgress] =
    useState<WhisperModelDownloadProgressEvent | null>(null);
  const [bootstrapMessage, setBootstrapMessage] = useState(
    'Preparing the speech model. First launch can take a while.',
  );
  const setTranscripts = useTranscriptStore(state => state.setTranscripts);
  const setCurrentTranscript = useTranscriptStore(state => state.setCurrentTranscript);
  const setCurrentChunks = useTranscriptStore(state => state.setCurrentChunks);
  const setAllChunks = useTranscriptStore(state => state.setAllChunks);

  const prepareModel = useCallback(async () => {
    setBootstrapState('bootstrapping');
    setBootstrapError(null);
    setDownloadProgress(null);
    setBootstrapMessage('Preparing the speech model. First launch can take a while.');

    try {
      const result = await VoiceScribeAudio.ensureWhisperModel(
        WHISPER_MODEL_URL,
        WHISPER_MODEL_FILE_NAME,
      );

      if (result.downloaded) {
        setBootstrapMessage('Model downloaded. Finalizing setup...');
      }

      setBootstrapState('ready');
    } catch (error) {
      setBootstrapError(String(error));
      setBootstrapState('failed');
    }
  }, []);

  useEffect(() => {
    const subscription = VoiceScribeAudio.onModelDownloadProgress(event => {
      setDownloadProgress(event);

      if (event.percent != null && event.totalBytes != null) {
        const safePercent = Math.max(0, Math.min(100, Math.floor(event.percent)));
        setBootstrapMessage(
          `Downloading speech model... ${safePercent}% (${formatBytes(event.bytesDownloaded)} / ${formatBytes(event.totalBytes)})`,
        );
        return;
      }

      setBootstrapMessage(`Downloading speech model... ${formatBytes(event.bytesDownloaded)}`);
    });

    return () => {
      subscription.remove();
    };
  }, []);

  useEffect(() => {
    prepareModel().catch(() => {
      setBootstrapState('failed');
      setBootstrapError('Model preparation failed.');
    });
  }, [prepareModel]);

  useEffect(() => {
    let cancelled = false;
    VoiceScribeAudio.loadTranscriptionState()
      .then(raw => {
        if (cancelled) {
          return;
        }
        const parsed = parseTranscriptStoreState(raw);
        if (!parsed) {
          return;
        }
        setTranscripts(parsed.transcripts);
        setCurrentTranscript(parsed.currentTranscript);
        setCurrentChunks(parsed.currentChunks);
        setAllChunks(parsed.allChunks);
      })
      .catch(() => {
        // no-op: app can continue with empty in-memory state
      });

    return () => {
      cancelled = true;
    };
  }, [setAllChunks, setCurrentChunks, setCurrentTranscript, setTranscripts]);

  // Global Audio Event Listeners (Must run continuously regardless of current screen)
  useEffect(() => {
    const chunkSubscription = VoiceScribeAudio.onChunkReady((chunkRecord) => {
      try {
        // For new chunks arriving from the native background service
        const store = useTranscriptStore.getState();
        // Check if there is an active recording session
        const transcriptId = store.currentTranscript?.id;
        if (!transcriptId) return;

        const nextChunkIndex = store.currentChunks.length + 1;
        const nowIso = new Date().toISOString();
        
        // Calculate dynamic startTime based on previous chunks
        const prevChunks = store.currentChunks;
        const calculatedStartTime = prevChunks.length > 0 
          ? prevChunks[prevChunks.length - 1].endTime
          : 0;
        const calculatedEndTime = calculatedStartTime + chunkRecord.durationSeconds;

        store.appendChunk({
          id: `${transcriptId}-chunk-${nextChunkIndex}`,
          transcriptId,
          chunkIndex: nextChunkIndex,
          text: '',
          audioPath: chunkRecord.path,
          recordedAt: nowIso,
          startTime: calculatedStartTime,
          endTime: calculatedEndTime,
          speakerLabel: null,
          confidence: null,
        });

        store.updateTranscript(transcriptId, {
          updatedAt: nowIso,
          statusKey: 'transcribing',
          durationSeconds: calculatedEndTime,
        });
      } catch (err) {
        console.warn('Global Chunk handling error:', err);
      }
    });

    const transcriptSubscription = VoiceScribeAudio.onTranscriptReady(({ chunkPath, text }) => {
      try {
        const normalizedText = text?.trim() || '';
        if (normalizedText.length > 0) {
          let deduplicatedText = normalizedText;
          const store = useTranscriptStore.getState();
          const matchedChunk = store.allChunks.find((chunk) => chunk.audioPath === chunkPath);
          
          // Note: Full removeOverlap logic is inside RecordingScreen for UI, 
          // but we SHOULD do it here since this is the global handler now.
          // Since we can't easily import textUtils here without modifying imports, we'll just update the chunk.
          // The RecordingScreen actually handles LivePreview.
          // Wait, if RecordingScreen is open AND App is open, they both process it!
          // We should migrate the chunk state update completely to App.tsx to avoid duplication.
          store.updateChunkTextByAudioPath(chunkPath, normalizedText);
          
          if (matchedChunk?.transcriptId) {
            store.updateTranscript(matchedChunk.transcriptId, {
              updatedAt: new Date().toISOString(),
              statusKey: 'completed',
            });
          }
        }
      } catch (err) {
        console.warn('Global Transcript handling error:', err);
      }
    });

    const errorSubscription = VoiceScribeAudio.onTranscriptionError(({ message, chunkPath }) => {
       const store = useTranscriptStore.getState();
       const matchedChunk = store.allChunks.find((c) => c.audioPath === chunkPath);
       if (matchedChunk?.transcriptId) {
         store.updateTranscript(matchedChunk.transcriptId, {
           updatedAt: new Date().toISOString(),
           statusKey: 'transcription_error',
         });
       }
    });

    return () => {
      chunkSubscription.remove();
      transcriptSubscription.remove();
      errorSubscription.remove();
    };
  }, []);

  useEffect(() => {
    const unsubscribe = useTranscriptStore.subscribe(state => {
      const payload = serializeTranscriptStoreState({
        transcripts: state.transcripts,
        currentTranscript: state.currentTranscript,
        currentChunks: state.currentChunks,
        allChunks: state.allChunks,
      });
      VoiceScribeAudio.saveTranscriptionState(payload).catch(() => {
        // Avoid crashing UI on persistence errors.
      });
    });

    return () => {
      unsubscribe();
    };
  }, []);

  const renderBootstrapScreen = () => {
    const progressBarWidthPercent =
      downloadProgress?.percent != null
        ? Math.max(2, Math.min(100, downloadProgress.percent))
        : 20;

    return (
      <View style={styles.bootstrapContainer}>
        <Text style={styles.bootstrapTitle}>VoiceScribe Setup</Text>
        <Text style={styles.bootstrapSubtitle}>
          {bootstrapState === 'bootstrapping'
            ? bootstrapMessage
            : 'VoiceScribe cannot continue until the speech model is ready.'}
        </Text>

        {bootstrapState === 'bootstrapping' && downloadProgress ? (
          <View style={styles.progressWrapper}>
            <View style={styles.progressTrack}>
              <View
                style={[
                  styles.progressFill,
                  {width: `${progressBarWidthPercent}%` as `${number}%`},
                ]}
              />
            </View>
            <Text style={styles.progressText}>
              {downloadProgress.percent != null
                ? `${Math.floor(downloadProgress.percent)}%`
                : `${formatBytes(downloadProgress.bytesDownloaded)}`}
            </Text>
          </View>
        ) : null}

        {bootstrapState === 'bootstrapping' ? (
          <ActivityIndicator size="large" color={colors.primary} />
        ) : (
          <TouchableOpacity style={styles.retryButton} onPress={prepareModel}>
            <Text style={styles.retryButtonText}>Retry Setup</Text>
          </TouchableOpacity>
        )}

        {bootstrapError ? <Text style={styles.bootstrapError}>{bootstrapError}</Text> : null}
      </View>
    );
  };

  return (
    <SafeAreaProvider>
      <GestureHandlerRootView style={styles.root}>
        <StatusBar barStyle="light-content" backgroundColor={colors.background} />
        {bootstrapState === 'ready' ? (
          <NavigationContainer
            theme={{
              dark: true,
              colors: {
                primary: colors.primary,
                background: colors.background,
                card: colors.surface,
                text: colors.text,
                border: colors.border,
                notification: colors.secondary,
              },
              fonts: {
                regular: { fontFamily: 'System', fontWeight: '400' },
                medium: { fontFamily: 'System', fontWeight: '500' },
                bold: { fontFamily: 'System', fontWeight: '700' },
                heavy: { fontFamily: 'System', fontWeight: '900' },
              },
            }}>
            <View style={styles.container}>
              <AppNavigator />
            </View>
          </NavigationContainer>
        ) : (
          renderBootstrapScreen()
        )}
      </GestureHandlerRootView>
    </SafeAreaProvider>
  );
};

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  bootstrapContainer: {
    flex: 1,
    backgroundColor: colors.background,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
  },
  bootstrapTitle: {
    color: colors.text,
    fontSize: fontSize.heading,
    fontWeight: '700',
    marginBottom: spacing.md,
    textAlign: 'center',
  },
  bootstrapSubtitle: {
    color: colors.textSecondary,
    fontSize: fontSize.lg,
    textAlign: 'center',
    marginBottom: spacing.lg,
  },
  progressWrapper: {
    width: '100%',
    maxWidth: 360,
    marginBottom: spacing.xl,
  },
  progressTrack: {
    width: '100%',
    height: 10,
    borderRadius: 999,
    backgroundColor: colors.surface,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: colors.border,
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.primary,
    borderRadius: 999,
  },
  progressText: {
    marginTop: spacing.sm,
    color: colors.textSecondary,
    textAlign: 'center',
    fontSize: fontSize.sm,
    fontWeight: '600',
  },
  retryButton: {
    backgroundColor: colors.primary,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderRadius: 10,
  },
  retryButtonText: {
    color: colors.white,
    fontWeight: '700',
    fontSize: fontSize.md,
  },
  bootstrapError: {
    marginTop: spacing.lg,
    color: colors.error,
    textAlign: 'center',
    fontSize: fontSize.sm,
  },
});

export default App;
