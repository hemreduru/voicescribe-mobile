import React, { useMemo, useState } from 'react';
import {
  FlatList,
  Modal,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  Pressable,
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
  Clock,
  ChevronLeft,
  MoreVertical,
} from 'lucide-react-native';
import { useColors } from '../../../../shared/theme';
import { spacing, borderRadius, fontSize, fontWeight } from '../../../../shared/theme/tokens';
import { GlassCard } from '../../../../shared/components/GlassCard';
import { SearchBar } from '../../../../shared/components/SearchBar';
import { ScreenHeader } from '../../../../shared/components/ScreenHeader';
import { useTranscriptStore } from '../../../../shared/stores';
import { useTranslation } from '../../../../shared/i18n';
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
  const t = useTranslation();

  const getStatusDisplay = () => {
    switch (item.statusKey) {
      case 'completed': return { bg: colors.successLight, text: colors.successText, label: t.status_completed };
      case 'recording': return { bg: colors.warningLight, text: colors.warning, label: t.status_recording };
      case 'transcribing': return { bg: colors.warningLight, text: colors.warning, label: t.status_transcribing };
      case 'transcription_error': return { bg: colors.errorLight, text: colors.errorText, label: t.status_transcription_error };
      default: return { bg: colors.surfaceVariant, text: colors.textSecondary, label: t.status_empty };
    }
  };

  const status = getStatusDisplay();

  return (
    <Pressable onPress={onPress}>
      {({ pressed }) => (
        <GlassCard style={[styles.sessionCard, pressed && { borderColor: colors.primary, borderWidth: 1 }]}>
          <View style={styles.cardHeader}>
            <Text style={[styles.sessionTitle, { color: colors.text }]} numberOfLines={1}>
              {item.title}
            </Text>
            <View style={[styles.statusBadge, { backgroundColor: status.bg }]}>
              <Text style={[styles.statusBadgeText, { color: status.text }]}>
                {status.label}
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
        </GlassCard>
      )}
    </Pressable>
  );
};

// Segment rendering completely removed per requirements

export const TranscriptScreen: React.FC = () => {
  const colors = useColors();
  const t = useTranslation();
  const transcripts = useTranscriptStore((state) => state.transcripts);
  const allChunks = useTranscriptStore((state) => state.allChunks);
  const [selectedSession, setSelectedSession] = useState<SessionCardItem | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [detailSearchQuery, setDetailSearchQuery] = useState('');
  const [showDropdown, setShowDropdown] = useState(false);

  const getStatusDisplay = (statusKey?: string) => {
    switch (statusKey) {
      case 'completed': return { bg: colors.successLight, text: colors.successText, label: t.status_completed };
      case 'recording': return { bg: colors.warningLight, text: colors.warning, label: t.status_recording };
      case 'transcribing': return { bg: colors.warningLight, text: colors.warning, label: t.status_transcribing };
      case 'transcription_error': return { bg: colors.errorLight, text: colors.errorText, label: t.status_transcription_error };
      default: return { bg: colors.surfaceVariant, text: colors.textSecondary, label: t.status_empty };
    }
  };

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
    setShowDropdown(false);
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
    setShowDropdown(false);
  };

  // Session List View
  if (!selectedSession) {
    if (sessionCards.length === 0) {
      return (
        <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]} edges={['top']}>
          <ScreenHeader title={t.transcript} />
          <View style={styles.content}>
            <Text style={styles.icon}>📝</Text>
            <Text style={[styles.title, { color: colors.text }]}>{t.transcript}</Text>
            <Text style={[styles.subtitle, { color: colors.textSecondary }]}>
              {t.transcriptEmptyDesc}
            </Text>
          </View>
        </SafeAreaView>
      );
    }

    return (
      <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]} edges={['top']}>
        <ScreenHeader title={t.transcript} />
        {/* Sticky Header */}
        <View style={[styles.stickyHeader, { backgroundColor: colors.background }]}>
          <SearchBar
            value={searchQuery}
            onChangeText={setSearchQuery}
            placeholder={t.searchRecordings}
            style={styles.searchBar}
          />
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

  const isTranscribing = selectedSession?.statusKey === 'recording' || selectedSession?.statusKey === 'transcribing';

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
        <View style={[styles.modalStickyHeader, { backgroundColor: colors.background, borderBottomColor: colors.border, zIndex: 10 }]}>
          <View style={styles.modalHeaderTop}>
            <TouchableOpacity onPress={closeModal} style={styles.backButton}>
              <ChevronLeft size={24} color={colors.text} />
            </TouchableOpacity>
            <Text style={[styles.modalTitle, { color: colors.text }]} numberOfLines={1}>
              {selectedSession?.title}
            </Text>
            <View style={{ position: 'relative' }}>
              <TouchableOpacity onPress={() => setShowDropdown(!showDropdown)} style={styles.kebabButton}>
                <MoreVertical size={24} color={colors.text} />
              </TouchableOpacity>
              {showDropdown && (
                <View style={[styles.dropdownMenu, { backgroundColor: colors.surface, borderColor: colors.border }]}>
                  <TouchableOpacity style={styles.dropdownItem} onPress={handleEdit}>
                    <Edit size={16} color={colors.text} />
                    <Text style={[styles.dropdownText, { color: colors.text }]}>{t.edit}</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.dropdownItem} onPress={handleCopy}>
                    <Copy size={16} color={colors.text} />
                    <Text style={[styles.dropdownText, { color: colors.text }]}>{t.copy}</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.dropdownItem} onPress={handleExport}>
                    <Download size={16} color={colors.text} />
                    <Text style={[styles.dropdownText, { color: colors.text }]}>{t.export}</Text>
                  </TouchableOpacity>
                </View>
              )}
            </View>
          </View>
          <SearchBar
            value={detailSearchQuery}
            onChangeText={setDetailSearchQuery}
            placeholder={t.searchRecordings}
            style={styles.modalSearchBar}
          />
        </View>

        <ScrollView style={styles.modalContent} contentContainerStyle={styles.modalScrollContent}>
          {/* Top Status & Duration Info */}
          <View style={styles.sessionMetaContainer}>
            <View style={[styles.statusBadge, { backgroundColor: getStatusDisplay(selectedSession?.statusKey).bg }]}>
              <Text style={[styles.statusBadgeText, { color: getStatusDisplay(selectedSession?.statusKey).text }]}>
                {getStatusDisplay(selectedSession?.statusKey).label}
              </Text>
            </View>
            <View style={styles.durationBadge}>
              <Clock size={16} color={colors.textSecondary} />
              <Text style={[styles.durationText, { color: colors.textSecondary }]}>
                {selectedSession?.durationLabel}
              </Text>
            </View>
          </View>

          {/* Unified Transcript Block */}
          {selectedSession?.mergedText && selectedSession.mergedText.length > 0 ? (
            <View style={[
              styles.mergedTextContainer, 
              { 
                backgroundColor: isTranscribing ? colors.warningLight : colors.successLight,
                borderColor: isTranscribing ? colors.warning : colors.success,
              }
            ]}>
              <Text style={[styles.mergedText, { color: isTranscribing ? colors.text : colors.successText }]}>
                {selectedSession.mergedText}
              </Text>
            </View>
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
    paddingHorizontal: spacing.lg,
    paddingBottom: spacing.lg,
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
    paddingTop: spacing.md,
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
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.xs,
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
  kebabButton: {
    padding: spacing.xs,
  },
  dropdownMenu: {
    position: 'absolute',
    top: 40,
    right: 0,
    borderWidth: 1,
    borderRadius: borderRadius.md,
    minWidth: 150,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 4,
    zIndex: 999,
  },
  dropdownItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
    gap: spacing.sm,
  },
  dropdownText: {
    fontSize: fontSize.md,
  },
  sessionMetaContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.lg,
  },
  durationBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  durationText: {
    fontSize: fontSize.sm,
    fontWeight: '500',
  },
  mergedTextContainer: {
    borderWidth: 1,
    borderRadius: borderRadius.lg,
    padding: spacing.lg,
    marginBottom: spacing.xl,
  },
  mergedText: {
    fontSize: fontSize.md,
    lineHeight: 28,
  },
  emptyText: {
    fontSize: fontSize.md,
    textAlign: 'center',
    marginTop: spacing.xl,
  },
});
