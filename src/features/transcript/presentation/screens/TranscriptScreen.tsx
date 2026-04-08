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
import { colors, fontSize, spacing } from '../../../../shared/theme';
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
  if (durationSeconds <= 0) {
    return '0s';
  }

  const minutes = Math.floor(durationSeconds / 60);
  const seconds = durationSeconds % 60;
  if (minutes <= 0) {
    return `${seconds}s`;
  }

  return `${minutes}m ${seconds}s`;
};

const getSessionFallbackText = (statusKey: string): string => {
  if (statusKey === 'transcription_error') {
    return 'Transcription failed for this session.';
  }

  if (statusKey === 'transcribing') {
    return 'Transcription in progress... Please wait a moment.';
  }

  if (statusKey === 'completed') {
    return 'Transcript is being finalized...';
  }

  if (statusKey === 'empty') {
    return 'No speech was captured in this session.';
  }

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
        recordedAtLabel: new Date(transcript.recordedAt ?? transcript.createdAt).toLocaleString(),
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
          <Text style={styles.title}>Transcripts</Text>
          <Text style={styles.subtitle}>
            Each recording session appears here as one merged transcript.
          </Text>
          <Text style={styles.hint}>No meeting sessions yet.</Text>
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
            <Text style={styles.title}>Transcripts</Text>
            <Text style={styles.subtitle}>Recorded sessions: {sessionCards.length}</Text>
          </View>
        }
        renderItem={({ item }) => {
          const summaryText =
            item.mergedText.length > 0
              ? getSummary(item.mergedText, 150)
              : getSessionFallbackText(item.statusKey);

          return (
            <TouchableOpacity
              style={styles.sessionCard}
              onPress={() => setSelectedSession(item)}
              activeOpacity={0.7}
            >
              <View style={styles.cardHeader}>
                <Text style={styles.sessionTitle} numberOfLines={1}>
                  {item.title}
                </Text>
                <Text style={styles.statusBadge}>{item.statusKey}</Text>
              </View>
              <Text style={styles.sessionMeta}>
                {item.recordedAtLabel} • {item.durationLabel} • {item.chunkCount} chunks
              </Text>
              <Text style={styles.sessionSummary} numberOfLines={3}>
                {summaryText}
              </Text>
              <Text style={styles.tapHint}>Tap to view full transcript →</Text>
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
            <View style={styles.modalHeader}>
              <TouchableOpacity onPress={closeModal} style={styles.closeButton}>
                <Text style={styles.closeButtonText}>← Back</Text>
              </TouchableOpacity>
              <Text style={styles.modalTitle} numberOfLines={1}>
                {selectedSession.title}
              </Text>
            </View>

            <ScrollView style={styles.modalContent} contentContainerStyle={styles.modalScrollContent}>
              {/* Session Info */}
              <View style={styles.infoSection}>
                <Text style={styles.infoLabel}>📅 Recorded</Text>
                <Text style={styles.infoValue}>{selectedSession.recordedAtLabel}</Text>
              </View>
              <View style={styles.infoSection}>
                <Text style={styles.infoLabel}>⏱️ Duration</Text>
                <Text style={styles.infoValue}>{selectedSession.durationLabel}</Text>
              </View>
              <View style={styles.infoSection}>
                <Text style={styles.infoLabel}>📦 Chunks</Text>
                <Text style={styles.infoValue}>{selectedSession.chunkCount}</Text>
              </View>
              <View style={styles.infoSection}>
                <Text style={styles.infoLabel}>📊 Status</Text>
                <Text style={styles.infoValue}>{selectedSession.statusKey}</Text>
              </View>

              {/* Full Transcript */}
              <View style={styles.transcriptSection}>
                <Text style={styles.sectionTitle}>Full Transcript</Text>
                <Text style={styles.fullTranscript}>
                  {selectedSession.mergedText.length > 0
                    ? selectedSession.mergedText
                    : getSessionFallbackText(selectedSession.statusKey)}
                </Text>
              </View>
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
    paddingHorizontal: spacing.lg,
  },
  listContent: {
    paddingHorizontal: spacing.md,
    paddingBottom: spacing.xl,
  },
  header: {
    paddingTop: spacing.lg,
    paddingBottom: spacing.md,
  },
  icon: {
    fontSize: 64,
    marginBottom: spacing.md,
  },
  title: {
    fontSize: fontSize.heading,
    fontWeight: '700',
    color: colors.text,
    marginBottom: spacing.sm,
  },
  subtitle: {
    fontSize: fontSize.lg,
    color: colors.textSecondary,
    textAlign: 'center',
    marginBottom: spacing.lg,
  },
  hint: {
    fontSize: fontSize.sm,
    color: colors.textMuted,
    fontStyle: 'italic',
  },
  sessionCard: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 12,
    padding: spacing.md,
    marginBottom: spacing.sm,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  sessionTitle: {
    color: colors.text,
    fontSize: fontSize.lg,
    fontWeight: '700',
    flex: 1,
    marginRight: spacing.sm,
  },
  statusBadge: {
    backgroundColor: colors.primary,
    color: colors.background,
    fontSize: fontSize.xs,
    paddingHorizontal: spacing.sm,
    paddingVertical: 2,
    borderRadius: 4,
    overflow: 'hidden',
  },
  sessionMeta: {
    color: colors.textSecondary,
    fontSize: fontSize.xs,
    marginBottom: spacing.sm,
  },
  sessionSummary: {
    color: colors.text,
    fontSize: fontSize.md,
    lineHeight: 20,
    marginBottom: spacing.xs,
  },
  tapHint: {
    color: colors.primary,
    fontSize: fontSize.xs,
    fontWeight: '600',
    marginTop: spacing.xs,
  },
  // Modal Styles
  modalContainer: {
    flex: 1,
    backgroundColor: colors.background,
  },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
    backgroundColor: colors.surface,
  },
  closeButton: {
    paddingRight: spacing.md,
  },
  closeButtonText: {
    color: colors.primary,
    fontSize: fontSize.md,
    fontWeight: '600',
  },
  modalTitle: {
    flex: 1,
    fontSize: fontSize.lg,
    fontWeight: '700',
    color: colors.text,
  },
  modalContent: {
    flex: 1,
  },
  modalScrollContent: {
    padding: spacing.md,
    paddingBottom: spacing.xl * 2,
  },
  infoSection: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  infoLabel: {
    color: colors.textSecondary,
    fontSize: fontSize.md,
  },
  infoValue: {
    color: colors.text,
    fontSize: fontSize.md,
    fontWeight: '600',
  },
  transcriptSection: {
    marginTop: spacing.lg,
  },
  sectionTitle: {
    fontSize: fontSize.lg,
    fontWeight: '700',
    color: colors.text,
    marginBottom: spacing.md,
  },
  fullTranscript: {
    color: colors.text,
    fontSize: fontSize.md,
    lineHeight: 24,
    backgroundColor: colors.surface,
    padding: spacing.md,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.border,
  },
  chunksSection: {
    marginTop: spacing.lg,
  },
  chunkItem: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.sm,
    marginBottom: spacing.sm,
  },
  chunkHeader: {
    fontSize: fontSize.xs,
    color: colors.textMuted,
    fontWeight: '600',
    marginBottom: spacing.xs,
  },
  chunkText: {
    fontSize: fontSize.sm,
    color: colors.text,
    lineHeight: 20,
  },
});
