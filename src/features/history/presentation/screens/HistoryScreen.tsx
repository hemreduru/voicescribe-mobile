import React, { useState, useMemo } from 'react';
import {
  StyleSheet,
  Text,
  View,
  FlatList,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Search, Filter, Trash2, MoreVertical, Play, FileText, Cloud, Check } from 'lucide-react-native';
import { useColors } from '../../../../shared/theme';
import { spacing, fontSize, borderRadius } from '../../../../shared/theme/tokens';
import { GlassCard } from '../../../../shared/components/GlassCard';
import { Badge } from '../../../../shared/components/Badge';
import { SearchBar } from '../../../../shared/components/SearchBar';
import { GlowButton } from '../../../../shared/components/GlowButton';
import { ScreenHeader } from '../../../../shared/components/ScreenHeader';
import { useTranscriptStore } from '../../../../shared/stores/useTranscriptStore';
import { useTranslation } from '../../../../shared/i18n';
import type { Transcript } from '../../../../shared/types';

type SortOption = 'newest' | 'oldest' | 'longest';

export const HistoryScreen: React.FC = () => {
  const colors = useColors();
  const t = useTranslation();
  
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<SortOption>('newest');
  const [selectedItems, setSelectedItems] = useState<string[]>([]);
  
  const transcripts = useTranscriptStore((state) => state.transcripts);
  const allChunks = useTranscriptStore((state) => state.allChunks);
  const removeTranscript = useTranscriptStore((state) => state.removeTranscript);

  // Filter and sort transcripts
  const filteredTranscripts = useMemo(() => {
    let filtered = transcripts.filter((t: Transcript) => 
      t.title?.toLowerCase().includes(searchQuery.toLowerCase()) ?? false
    );

    // Sort
    switch (sortBy) {
      case 'newest':
        filtered.sort((a: Transcript, b: Transcript) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
        break;
      case 'oldest':
        filtered.sort((a: Transcript, b: Transcript) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
        break;
      case 'longest':
        filtered.sort((a: Transcript, b: Transcript) => b.durationSeconds - a.durationSeconds);
        break;
    }

    return filtered;
  }, [transcripts, searchQuery, sortBy]);

  // Get chunks for a transcript
  const getTranscriptChunks = (transcriptId: string) => {
    return allChunks.filter((c) => c.transcriptId === transcriptId);
  };

  // Toggle selection
  const toggleSelect = (id: string) => {
    setSelectedItems(prev => 
      prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]
    );
  };

  // Toggle select all
  const toggleSelectAll = () => {
    if (selectedItems.length === filteredTranscripts.length) {
      setSelectedItems([]);
    } else {
      setSelectedItems(filteredTranscripts.map((t: Transcript) => t.id));
    }
  };

  // Handle delete
  const handleDelete = () => {
    if (selectedItems.length === 0) return;
    
    Alert.alert(
      'Kayıtları Sil',
      `${selectedItems.length} kaydı silmek istediğinize emin misiniz?`,
      [
        { text: 'İptal', style: 'cancel' },
        { 
          text: 'Sil', 
          style: 'destructive',
          onPress: () => {
            selectedItems.forEach(id => removeTranscript(id));
            setSelectedItems([]);
          }
        },
      ]
    );
  };

  // Format duration
  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  // Format date
  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    const day = date.getDate().toString().padStart(2, '0');
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const year = date.getFullYear();
    return `${day}.${month}.${year}`;
  };

  // Format time
  const formatTime = (dateStr: string) => {
    const date = new Date(dateStr);
    const hours = date.getHours().toString().padStart(2, '0');
    const mins = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${mins}`;
  };

  const hasSelection = selectedItems.length > 0;
  const allSelected = selectedItems.length === filteredTranscripts.length && filteredTranscripts.length > 0;

  const renderRecordingCard = ({ item }: { item: Transcript }) => {
    const isSelected = selectedItems.includes(item.id);
    const chunks = getTranscriptChunks(item.id);
    const hasTranscript = chunks.length > 0;
    const hasSummary = false; // TODO: Add summary check when summary store is ready

    const dateStr = item.recordedAt || item.createdAt;

    return (
      <GlassCard
        style={[
          styles.card,
          isSelected && { 
            borderColor: colors.primary,
            borderWidth: 2,
          }
        ]}
      >
        <TouchableOpacity style={styles.cardContent} onPress={() => toggleSelect(item.id)}>
          {/* Checkbox */}
          <TouchableOpacity 
            style={[
              styles.checkbox,
              isSelected && styles.checkboxSelected
            ]}
            onPress={() => toggleSelect(item.id)}
          >
            {isSelected && <Check size={16} color={colors.white} />}
          </TouchableOpacity>

          {/* Content */}
          <View style={styles.cardMain}>
            <Text style={[styles.cardTitle, { color: colors.text }]} numberOfLines={1}>
              {item.title || `Kayıt ${item.localId}`}
            </Text>
            
            <Text style={[styles.meta, { color: colors.textSecondary }]}>
              {formatDate(dateStr)} • {formatTime(dateStr)} • {formatDuration(item.durationSeconds)}
            </Text>

            {/* Badges */}
            <View style={styles.badges}>
              <Badge 
                label="Senkron" 
                variant="sync" 
                icon={<Cloud size={12} color={colors.syncBadgeText} />}
              />
              {hasTranscript && (
                <Badge 
                  label="Transkript" 
                  variant="transcript" 
                  icon={<FileText size={12} color={colors.transcriptBadgeText} />}
                />
              )}
              {hasSummary && (
                <Badge 
                  label="Özet" 
                  variant="summary" 
                  icon={<FileText size={12} color={colors.summaryBadgeText} />}
                />
              )}
            </View>
          </View>

          {/* Actions */}
          <View style={styles.cardActions}>
            <TouchableOpacity style={styles.actionButton}>
              <Play size={20} color={colors.primary} />
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionButton}>
              <MoreVertical size={20} color={colors.textSecondary} />
            </TouchableOpacity>
          </View>
        </TouchableOpacity>
      </GlassCard>
    );
  };

  const renderEmptyState = () => (
    <View style={styles.emptyContainer}>
      <GlassCard intensity="medium" padding="lg" style={styles.emptyState}>
        <Text style={styles.icon}>📁</Text>
        <Text style={[styles.emptyTitle, { color: colors.text }]}>Kayıt Bulunamadı</Text>
        <Text style={[styles.emptyDesc, { color: colors.textSecondary }]}>
          {searchQuery ? 'Arama kriterlerinize uygun kayıt yok.' : 'Henüz hiç kayıtınız yok.'}
        </Text>
      </GlassCard>
    </View>
  );

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]} edges={['top']}>
      <ScreenHeader title={t.history} />
      {/* Sticky Header */}
      <View style={[styles.header, { backgroundColor: colors.background }]}>
          {hasSelection && (
            <GlowButton
              title={`${t.delete} (${selectedItems.length})`}
              variant="danger"
              size="sm"
              icon={<Trash2 size={16} color={colors.white} />}
              onPress={handleDelete}
            />
          )}

        <View style={styles.searchRow}>
          <SearchBar
            value={searchQuery}
            onChangeText={setSearchQuery}
            placeholder="Kayıtlarda ara..."
            style={styles.searchBar}
          />
          
          <TouchableOpacity
            style={[styles.iconButton, { backgroundColor: colors.surfaceSecondary }]}
            onPress={() => {/* TODO: Show filter modal */}}
          >
            <Filter size={20} color={colors.textSecondary} />
          </TouchableOpacity>
        </View>

        <View style={styles.sortRow}>
          <TouchableOpacity 
            style={[
              styles.sortButton, 
              sortBy === 'newest' && { backgroundColor: colors.primaryLight }
            ]}
            onPress={() => setSortBy('newest')}
          >
            <Text style={[
              styles.sortButtonText, 
              { color: sortBy === 'newest' ? colors.primary : colors.textSecondary }
            ]}>
              En Yeni
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[
              styles.sortButton, 
              sortBy === 'oldest' && { backgroundColor: colors.primaryLight }
            ]}
            onPress={() => setSortBy('oldest')}
          >
            <Text style={[
              styles.sortButtonText, 
              { color: sortBy === 'oldest' ? colors.primary : colors.textSecondary }
            ]}>
              En Eski
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[
              styles.sortButton, 
              sortBy === 'longest' && { backgroundColor: colors.primaryLight }
            ]}
            onPress={() => setSortBy('longest')}
          >
            <Text style={[
              styles.sortButtonText, 
              { color: sortBy === 'longest' ? colors.primary : colors.textSecondary }
            ]}>
              En Uzun
            </Text>
          </TouchableOpacity>
        </View>

        {filteredTranscripts.length > 0 && (
          <TouchableOpacity style={styles.selectAllRow} onPress={toggleSelectAll}>
            <View style={[styles.smallCheckbox, allSelected && styles.smallCheckboxSelected]}>
              {allSelected && <Check size={12} color={colors.white} />}
            </View>
            <Text style={[styles.selectAllText, { color: colors.textSecondary }]}>
              {allSelected ? 'Tümünü Seçimi Kaldır' : 'Tümünü Seç'}
            </Text>
          </TouchableOpacity>
        )}
      </View>

      {/* Recording List */}
      {filteredTranscripts.length === 0 ? (
        renderEmptyState()
      ) : (
        <FlatList
          data={filteredTranscripts}
          renderItem={renderRecordingCard}
          keyExtractor={item => item.id}
          contentContainerStyle={styles.listContent}
          showsVerticalScrollIndicator={false}
        />
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingHorizontal: spacing.lg,
    paddingBottom: spacing.md,
  },
  headerTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  headerTitle: {
    fontSize: fontSize.heading,
    fontWeight: '700',
  },
  searchRow: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginBottom: spacing.sm,
  },
  searchBar: {
    flex: 1,
  },
  iconButton: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.lg,
    justifyContent: 'center',
    alignItems: 'center',
  },
  sortRow: {
    flexDirection: 'row',
    gap: spacing.xs,
    marginBottom: spacing.sm,
  },
  sortButton: {
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.md,
  },
  sortButtonText: {
    fontSize: fontSize.sm,
    fontWeight: '500',
  },
  selectAllRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginTop: spacing.xs,
  },
  smallCheckbox: {
    width: 18,
    height: 18,
    borderRadius: 4,
    borderWidth: 2,
    borderColor: '#d1d5db',
    justifyContent: 'center',
    alignItems: 'center',
  },
  smallCheckboxSelected: {
    backgroundColor: '#db2777',
    borderColor: '#db2777',
  },
  selectAllText: {
    fontSize: fontSize.sm,
  },
  listContent: {
    padding: spacing.lg,
    paddingBottom: 100,
  },
  card: {
    marginBottom: spacing.md,
  },
  cardContent: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  checkbox: {
    width: 24,
    height: 24,
    borderRadius: 6,
    borderWidth: 2,
    borderColor: '#d1d5db',
    marginRight: spacing.md,
    marginTop: 2,
    justifyContent: 'center',
    alignItems: 'center',
  },
  checkboxSelected: {
    backgroundColor: '#db2777',
    borderColor: '#db2777',
  },
  cardMain: {
    flex: 1,
  },
  cardTitle: {
    fontSize: fontSize.md,
    fontWeight: '500',
    marginBottom: spacing.xs,
  },
  meta: {
    fontSize: fontSize.xs,
    marginBottom: spacing.sm,
  },
  badges: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.xs,
  },
  cardActions: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginLeft: spacing.md,
  },
  actionButton: {
    padding: spacing.xs,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyState: {
    alignItems: 'center',
  },
  icon: {
    fontSize: 48,
    marginBottom: spacing.md,
  },
  emptyTitle: {
    fontSize: fontSize.xl,
    fontWeight: '600',
    marginBottom: spacing.sm,
    textAlign: 'center',
  },
  emptyDesc: {
    fontSize: fontSize.md,
    textAlign: 'center',
    lineHeight: 22,
  },
});
