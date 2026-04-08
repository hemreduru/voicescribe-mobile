import React, { useMemo, useState } from 'react';
import {
  FlatList,
  Modal,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { colors, fontSize, spacing, borderRadius } from '../../../../shared/theme';
import { GlassCard } from '../../../../shared/components/GlassCard';
import { useTranscriptStore } from '../../../../shared/stores';
import type { Transcript, TranscriptChunk } from '../../../../shared/types';

interface SessionCardItem {
  id: string;
  title: string;
  recordedAtLabel: string;
  durationLabel: string;
  chunkCount: number;
  statusKey: string;
  mergedText: string;
  chunks: TranscriptChunk[];
}

const formatDuration = (durationSeconds: number): string => {
  if (durationSeconds <= 0) return '0s';
  const minutes = Math.floor(durationSeconds / 60);
  const seconds = durationSeconds % 60;
  if (minutes <= 0) return `${seconds}s`;
  return `${minutes}m ${seconds}s`;
};

const getSessionFallbackText = (statusKey: string): string => {
  if (statusKey === 'transcription_error') return 'Transcription failed for this session.';
  if (statusKey === 'transcribing') return 'Transcription in progress... Please wait a moment.';
  if (statusKey === 'completed') return 'Transcript is being finalized...';
  if (statusKey === 'empty') return 'No speech was captured in this session.';
  return 'No transcript text generated yet.';
};

const getSummary = (text: string, maxLen: number = 150): string => {
  if (text.length <= maxLen) return text;
  const truncated = text.slice(0, maxLen).trim();
  const lastSpace = truncated.lastIndexOf(' ');
  return (lastSpace > 50 ? truncated.slice(0, lastSpace) : truncated) + '...';
};

const buildSessionCards = (
  transcripts: Transcript[],
  allChunks: TranscriptChunk[],
): SessionCardItem[] => {
  const chunksByTranscriptId = new Map<string, TranscriptChunk[]>();

  for (const chunk of allChunks) {
    const existing = chunksByTranscriptId.get(chunk.transcriptId) ?? [];
    existing.push(chunk);
    chunksByTranscriptId.set(chunk.transcriptId, existing);
  }

  return [...transcripts]
    .sort((a, b) => {
      const aTime = Date.parse(a.recordedAt ?? a.createdAt);
      const bTime = Date.parse(b.recordedAt ?? b.createdAt);
      return bTime - aTime;
    })
    .map((transcript) => {
      const sessionChunks = [...(chunksByTranscriptId.get(transcript.id) ?? [])].sort(
        (a, b) => a.chunkIndex - b.chunkIndex,
      );
      const mergedText = sessionChunks
        .map((chunk) => chunk.text.trim())
        .filter((chunkText) => chunkText.length > 0)
        .join(' ')
        .replace(/\s+/g, ' ')
        .trim();
      const safeTitle = transcript.title?.trim() || new Date(transcript.createdAt).toLocaleString();

      return {
        id: transcript.id,
        title: safeTitle,
        recordedAtLabel: new Date(transcript.recordedAt ?? transcript.createdAt).toLocaleDateString(undefined, {
          month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
        }),
        durationLabel: formatDuration(transcript.durationSeconds),
        chunkCount: sessionChunks.length,
        statusKey: transcript.statusKey,
        mergedText,
        chunks: sessionChunks,
      };
    });
};

export const TranscriptScreen: React.FC = () => {
  const transcripts = useTranscriptStore((state) => state.transcripts);
  const allChunks = useTranscriptStore((state) => state.allChunks);
  const [selectedSession, setSelectedSession] = useState<SessionCardItem | null>(null);

  const sessionCards = useMemo(() => {
    return buildSessionCards(transcripts, allChunks);
  }, [transcripts, allChunks]);

  const closeModal = () => setSelectedSession(null);

  if (sessionCards.length === 0) {
    return (
      <View style={styles.container}>
        <View style={styles.content}>
          <Text style={styles.icon}>📝</Text>
          <Text style={styles.title}>Logs</Text>
          <Text style={styles.subtitle}>
            Your audio archives will elegantly appear here.
          </Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={sessionCards}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        ListHeaderComponent={
          <View style={styles.header}>
            <Text style={styles.title}>Logs</Text>
            <Text style={styles.subtitle}>All recorded sessions</Text>
          </View>
        }
        renderItem={({ item }) => {
          const summaryText =
            item.mergedText.length > 0
              ? getSummary(item.mergedText, 150)
              : getSessionFallbackText(item.statusKey);

          return (
            <TouchableOpacity onPress={() => setSelectedSession(item)} activeOpacity={0.8}>
              <GlassCard intensity="low" padding="lg" style={styles.sessionCard}>
                <View style={styles.cardHeader}>
                  <Text style={styles.sessionTitle} numberOfLines={1}>{item.title}</Text>
                  <View style={styles.statusBadgeLayer}>
                    <Text style={styles.statusBadgeText}>{item.statusKey}</Text>
                  </View>
                </View>
                
                <View style={styles.metaRow}>
                  <Text style={styles.sessionMeta}>{item.recordedAtLabel}</Text>
                  <View style={styles.metaDot} />
                  <Text style={styles.sessionMeta}>{item.durationLabel}</Text>
                </View>

                <View style={styles.summaryContainer}>
                  <Text style={styles.sessionSummary} numberOfLines={3}>{summaryText}</Text>
                </View>
              </GlassCard>
            </TouchableOpacity>
          );
        }}
      />

      {/* Detail Modal */}
      <Modal
        visible={selectedSession !== null}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={closeModal}
      >
        {selectedSession && (
          <View style={styles.modalContainer}>
            <GlassCard intensity="medium" style={styles.modalHeader}>
              <TouchableOpacity onPress={closeModal} style={styles.closeButton}>
                <Text style={styles.closeButtonText}>Close</Text>
              </TouchableOpacity>
              <Text style={styles.modalTitle} numberOfLines={1}>
                {selectedSession.title}
              </Text>
            </GlassCard>

            <ScrollView style={styles.modalContent} contentContainerStyle={styles.modalScrollContent}>
              <View style={styles.inlineMetaRow}>
                <GlassCard padding="md" intensity="low" style={styles.metaChip}>
                  <Text style={styles.infoLabel}>Date</Text>
                  <Text style={styles.infoValue}>{selectedSession.recordedAtLabel}</Text>
                </GlassCard>
                <GlassCard padding="md" intensity="low" style={styles.metaChip}>
                  <Text style={styles.infoLabel}>Duration</Text>
                  <Text style={styles.infoValue}>{selectedSession.durationLabel}</Text>
                </GlassCard>
              </View>

              <GlassCard intensity="low" padding="lg" style={styles.transcriptSection}>
                <Text style={styles.fullTranscript}>
                  {selectedSession.mergedText.length > 0
                    ? selectedSession.mergedText
                    : getSessionFallbackText(selectedSession.statusKey)}
                </Text>
              </GlassCard>
            </ScrollView>
          </View>
        )}
      </Modal>
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
    paddingHorizontal: spacing.xl,
  },
  icon: {
    fontSize: 64,
    marginBottom: spacing.md,
  },
  header: {
    paddingTop: 60,
    paddingBottom: spacing.lg,
    paddingHorizontal: spacing.md,
  },
  title: {
    fontFamily: 'sans-serif-medium',
    fontSize: fontSize.display,
    fontWeight: '700',
    color: colors.text,
    letterSpacing: -1,
  },
  subtitle: {
    fontFamily: 'sans-serif',
    fontSize: fontSize.md,
    color: colors.textSecondary,
    marginTop: spacing.xs,
  },
  listContent: {
    paddingHorizontal: spacing.md,
    paddingBottom: 100, // Offset for global tab bar
  },
  sessionCard: {
    marginBottom: spacing.md,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  sessionTitle: {
    fontFamily: 'sans-serif-medium',
    color: colors.text,
    fontSize: fontSize.lg,
    fontWeight: '600',
    flex: 1,
    marginRight: spacing.sm,
  },
  statusBadgeLayer: {
    backgroundColor: colors.glowPrimary,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.sm,
  },
  statusBadgeText: {
    color: colors.primary,
    fontSize: fontSize.xs,
    fontFamily: 'sans-serif-medium',
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.lg,
  },
  metaDot: {
    width: 4,
    height: 4,
    borderRadius: 2,
    backgroundColor: colors.textMuted,
    marginHorizontal: spacing.sm,
  },
  sessionMeta: {
    fontFamily: 'sans-serif',
    color: colors.textSecondary,
    fontSize: fontSize.sm,
  },
  summaryContainer: {
    borderLeftWidth: 2,
    borderLeftColor: colors.primaryContainer,
    paddingLeft: spacing.md,
  },
  sessionSummary: {
    fontFamily: 'sans-serif',
    color: colors.text,
    fontSize: fontSize.md,
    lineHeight: 24,
    opacity: 0.9,
  },
  // Modal Styles
  modalContainer: {
    flex: 1,
    backgroundColor: colors.background,
  },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingTop: 50,
    paddingBottom: spacing.md,
    paddingHorizontal: spacing.lg,
    borderBottomWidth: 0,
    borderTopLeftRadius: 0,
    borderTopRightRadius: 0,
  },
  closeButton: {
    paddingVertical: spacing.sm,
    paddingRight: spacing.md,
  },
  closeButtonText: {
    fontFamily: 'sans-serif-medium',
    color: colors.primary,
    fontSize: fontSize.md,
  },
  modalTitle: {
    flex: 1,
    fontFamily: 'sans-serif-medium',
    fontSize: fontSize.lg,
    color: colors.text,
    textAlign: 'center',
    paddingRight: 40,
  },
  modalContent: {
    flex: 1,
  },
  modalScrollContent: {
    padding: spacing.lg,
    paddingBottom: spacing.xl * 3,
  },
  inlineMetaRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: spacing.lg,
    gap: spacing.md,
  },
  metaChip: {
    flex: 1,
    alignItems: 'center',
  },
  infoLabel: {
    fontFamily: 'sans-serif',
    color: colors.textSecondary,
    fontSize: fontSize.sm,
    marginBottom: 4,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  infoValue: {
    fontFamily: 'sans-serif-medium',
    color: colors.text,
    fontSize: fontSize.md,
  },
  transcriptSection: {
    marginTop: spacing.sm,
  },
  fullTranscript: {
    fontFamily: 'sans-serif',
    color: colors.text,
    fontSize: fontSize.lg, // Highly readable body
    lineHeight: 30,
    letterSpacing: 0.2,
  },
});

