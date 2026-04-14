import React, { useMemo, useState } from 'react';
import {
  FlatList,
  Modal,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  ViewStyle,
  TextStyle,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  Search,
  Copy,
  Download,
  Edit,
  Play,
  Clock,
  ChevronLeft,
} from 'lucide-react-native';
import { useColors } from '../../../../shared/theme';
import { spacing, borderRadius, fontSize, fontWeight } from '../../../../shared/theme/tokens';
import { GlassCard } from '../../../../shared/components/GlassCard';
import { SearchBar } from '../../../../shared/components/SearchBar';
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

interface SessionCardProps {
  item: SessionCardItem;
  onPress: () => void;
}

const SessionCard: React.FC<SessionCardProps> = ({ item, onPress }) => {
  const colors = useColors();

  const summaryText =
    item.mergedText.length > 0
      ? getSummary(item.mergedText, 150)
      : getSessionFallbackText(item.statusKey);

  return (
    <TouchableOpacity onPress={onPress} activeOpacity={0.7}>
      <GlassCard style={styles.sessionCard}>
        <View style={styles.cardHeader}>
          <Text style={[styles.sessionTitle, { color: colors.text }]} numberOfLines={1}>
            {item.title}
          </Text>
          <View style={[styles.statusBadge, { backgroundColor: colors.primaryContainer }]}>
            <Text style={[styles.statusBadgeText, { color: colors.primary }]}>
              {item.statusKey}
            </Text>
          </View>
        </View>

        <View style={styles.metaRow}>
          <Text style={[styles.sessionMeta, { color: colors.textSecondary }]}>
            {item.recordedAtLabel}
          </Text>
          <View style={[styles.metaDot, { backgroundColor: colors.textMuted }]} />
          <Text style={[styles.sessionMeta, { color: colors.textSecondary }]}>
            {item.durationLabel}
          </Text>
        </View>

        <View style={[styles.summaryContainer, { borderLeftColor: colors.primary }]}>
          <Text style={[styles.sessionSummary, { color: colors.text }]} numberOfLines={3}>
            {summaryText}
          </Text>
        </View>
      </GlassCard>
    </TouchableOpacity>
  );
};

interface TranscriptSegmentProps {
  segment: TranscriptChunk;
}

const TranscriptSegment: React.FC<TranscriptSegmentProps> = ({ segment }) => {
  const colors = useColors();

  return (
    <View style={[styles.segmentContainer, { borderLeftColor: colors.primary }]}>
      <View style={styles.segmentHeader}>
        <Text style={[styles.speakerLabel, { color: colors.primary }]}>
          {segment.speakerLabel || 'Speaker'}
        </Text>
        <View style={styles.timestampRow}>
          <Clock size={12} color={colors.textMuted} />
          <Text style={[styles.timestamp, { color: colors.textMuted }]}>
            {formatDuration(Math.floor(segment.startTime))}
          </Text>
        </View>
      </View>
      <Text style={[styles.segmentText, { color: colors.text }]}>
        {segment.text}
      </Text>
    </View>
  );
};

export const TranscriptScreen: React.FC = () => {
  const colors = useColors();
  const transcripts = useTranscriptStore((state) => state.transcripts);
  const allChunks = useTranscriptStore((state) => state.allChunks);
  const [selectedSession, setSelectedSession] = useState<SessionCardItem | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [detailSearchQuery, setDetailSearchQuery] = useState('');

  const sessionCards = useMemo(() => {
    return buildSessionCards(transcripts, allChunks);
  }, [transcripts, allChunks]);

  const filteredSessions = useMemo(() => {
    if (!searchQuery) return sessionCards;
    const query = searchQuery.toLowerCase();
    return sessionCards.filter(
      (card) =>
        card.title.toLowerCase().includes(query) ||
        card.mergedText.toLowerCase().includes(query),
    );
  }, [sessionCards, searchQuery]);

  const filteredChunks = useMemo(() => {
    if (!selectedSession) return [];
    if (!detailSearchQuery) return selectedSession.chunks;
    const query = detailSearchQuery.toLowerCase();
    return selectedSession.chunks.filter(
      (chunk) =>
        chunk.text.toLowerCase().includes(query) ||
        (chunk.speakerLabel && chunk.speakerLabel.toLowerCase().includes(query)),
    );
  }, [selectedSession, detailSearchQuery]);

  const closeModal = () => {
    setSelectedSession(null);
    setDetailSearchQuery('');
  };

  const handleCopy = () => {
    if (selectedSession) {
      // Copy transcript text to clipboard
      console.log('Copy transcript');
    }
  };

  const handleExport = () => {
    if (selectedSession) {
      // Export transcript
      console.log('Export transcript');
    }
  };

  const handleEdit = () => {
    if (selectedSession) {
      // Edit transcript
      console.log('Edit transcript');
    }
  };

  // Session List View
  if (!selectedSession) {
    if (sessionCards.length === 0) {
      return (
        <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]} edges={['top']}>
          <View style={styles.content}>
            <Text style={styles.icon}>📝</Text>
            <Text style={[styles.title, { color: colors.text }]}>Transkript</Text>
            <Text style={[styles.subtitle, { color: colors.textSecondary }]}>
              Your audio archives will elegantly appear here.
            </Text>
          </View>
        </SafeAreaView>
      );
    }

    return (
      <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]} edges={['top']}>
        {/* Sticky Header */}
        <View style={[styles.stickyHeader, { backgroundColor: colors.background, borderBottomColor: colors.border }]}>
          <Text style={[styles.headerTitle, { color: colors.text }]}>Transkript</Text>
          <SearchBar
            value={searchQuery}
            onChangeText={setSearchQuery}
            placeholder="Kayıtlarda ara..."
            style={styles.searchBar}
          />
          <View style={styles.actionButtonsRow}>
            <TouchableOpacity style={styles.actionButton}>
              <Copy size={20} color={colors.textSecondary} />
              <Text style={[styles.actionButtonText, { color: colors.textSecondary }]}>Kopyala</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionButton}>
              <Download size={20} color={colors.textSecondary} />
              <Text style={[styles.actionButtonText, { color: colors.textSecondary }]}>Dışa Aktar</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionButton}>
              <Edit size={20} color={colors.primary} />
              <Text style={[styles.actionButtonText, { color: colors.primary }]}>Düzenle</Text>
            </TouchableOpacity>
          </View>
        </View>

        <FlatList
          data={filteredSessions}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContent}
          renderItem={({ item }) => (
            <SessionCard item={item} onPress={() => setSelectedSession(item)} />
          )}
        />
      </SafeAreaView>
    );
  }

  // Session Detail View (Modal)
  return (
    <Modal
      visible={selectedSession !== null}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={closeModal}
    >
      <SafeAreaView style={[styles.modalContainer, { backgroundColor: colors.background }]} edges={['top']}>
        {/* Sticky Header */}
        <View style={[styles.modalStickyHeader, { backgroundColor: colors.background, borderBottomColor: colors.border }]}>
          <View style={styles.modalHeaderTop}>
            <TouchableOpacity onPress={closeModal} style={styles.backButton}>
              <ChevronLeft size={24} color={colors.text} />
            </TouchableOpacity>
            <Text style={[styles.modalTitle, { color: colors.text }]} numberOfLines={1}>
              {selectedSession.title}
            </Text>
          </View>
          <SearchBar
            value={detailSearchQuery}
            onChangeText={setDetailSearchQuery}
            placeholder="Metinde ara..."
            style={styles.modalSearchBar}
          />
          <View style={styles.actionButtonsRow}>
            <TouchableOpacity style={styles.actionButton} onPress={handleCopy}>
              <Copy size={20} color={colors.textSecondary} />
              <Text style={[styles.actionButtonText, { color: colors.textSecondary }]}>Kopyala</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionButton} onPress={handleExport}>
              <Download size={20} color={colors.textSecondary} />
              <Text style={[styles.actionButtonText, { color: colors.textSecondary }]}>Dışa Aktar</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionButton} onPress={handleEdit}>
              <Edit size={20} color={colors.primary} />
              <Text style={[styles.actionButtonText, { color: colors.primary }]}>Düzenle</Text>
            </TouchableOpacity>
          </View>
        </View>

        <ScrollView style={styles.modalContent} contentContainerStyle={styles.modalScrollContent}>
          {/* Recording Info Card */}
          <View style={[styles.recordingInfoCard, { backgroundColor: colors.primaryContainer, borderColor: colors.border }]}>
            <View style={styles.recordingInfoHeader}>
              <TouchableOpacity style={[styles.playButton, { backgroundColor: colors.primary }]}>
                <Play size={20} color={colors.textOnPrimary} fill={colors.textOnPrimary} />
              </TouchableOpacity>
              <View style={styles.recordingInfoText}>
                <Text style={[styles.recordingTitle, { color: colors.text }]}>
                  {selectedSession.title}
                </Text>
                <Text style={[styles.recordingDate, { color: colors.textSecondary }]}>
                  {selectedSession.recordedAtLabel}
                </Text>
              </View>
            </View>
          </View>

          {/* Transcript Segments */}
          {filteredChunks.length > 0 ? (
            filteredChunks.map((chunk) => (
              <TranscriptSegment key={chunk.id} segment={chunk} />
            ))
          ) : (
            <Text style={[styles.emptyText, { color: colors.textSecondary }]}>
              {detailSearchQuery ? 'No matching text found.' : 'No transcript available.'}
            </Text>
          )}
        </ScrollView>
      </SafeAreaView>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
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
  title: {
    fontSize: fontSize.heading,
    fontWeight: '700',
    marginBottom: spacing.sm,
  },
  subtitle: {
    fontSize: fontSize.md,
    textAlign: 'center',
  },
  // Sticky Header
  stickyHeader: {
    paddingTop: spacing.md,
    paddingBottom: spacing.lg,
    paddingHorizontal: spacing.lg,
    borderBottomWidth: 1,
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: '700',
    marginBottom: spacing.md,
  },
  searchBar: {
    marginBottom: spacing.md,
  },
  actionButtonsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
  },
  actionButtonText: {
    fontSize: fontSize.sm,
    fontWeight: fontWeight.medium,
  },
  // List Content
  listContent: {
    paddingHorizontal: spacing.lg,
    paddingBottom: 100,
  },
  // Session Card
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
    fontSize: fontSize.lg,
    fontWeight: '600',
    flex: 1,
    marginRight: spacing.sm,
  },
  statusBadge: {
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.sm,
  },
  statusBadgeText: {
    fontSize: fontSize.xs,
    fontWeight: fontWeight.semibold,
    textTransform: 'uppercase',
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  metaDot: {
    width: 4,
    height: 4,
    borderRadius: 2,
    marginHorizontal: spacing.sm,
  },
  sessionMeta: {
    fontSize: fontSize.sm,
  },
  summaryContainer: {
    borderLeftWidth: 4,
    paddingLeft: spacing.md,
  },
  sessionSummary: {
    fontSize: fontSize.md,
    lineHeight: 24,
  },
  // Modal Container
  modalContainer: {
    flex: 1,
  },
  modalStickyHeader: {
    paddingTop: spacing.md,
    paddingBottom: spacing.lg,
    paddingHorizontal: spacing.lg,
    borderBottomWidth: 1,
  },
  modalHeaderTop: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  backButton: {
    paddingVertical: spacing.sm,
    paddingRight: spacing.sm,
  },
  modalTitle: {
    flex: 1,
    fontSize: fontSize.lg,
    fontWeight: '600',
  },
  modalSearchBar: {
    marginBottom: spacing.md,
  },
  modalContent: {
    flex: 1,
  },
  modalScrollContent: {
    padding: spacing.lg,
    paddingBottom: spacing.xl * 3,
  },
  // Recording Info Card
  recordingInfoCard: {
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    padding: spacing.md,
    marginBottom: spacing.lg,
  },
  recordingInfoHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  playButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  recordingInfoText: {
    flex: 1,
  },
  recordingTitle: {
    fontSize: fontSize.md,
    fontWeight: '600',
    marginBottom: spacing.xs,
  },
  recordingDate: {
    fontSize: fontSize.sm,
  },
  // Transcript Segment
  segmentContainer: {
    borderLeftWidth: 4,
    paddingLeft: spacing.md,
    paddingVertical: spacing.sm,
    marginBottom: spacing.md,
  },
  segmentHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  speakerLabel: {
    fontSize: fontSize.sm,
    fontWeight: '600',
  },
  timestampRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  timestamp: {
    fontSize: fontSize.xs,
  },
  segmentText: {
    fontSize: fontSize.md,
    lineHeight: 24,
  },
  emptyText: {
    fontSize: fontSize.md,
    textAlign: 'center',
    marginTop: spacing.xl,
  },
});
