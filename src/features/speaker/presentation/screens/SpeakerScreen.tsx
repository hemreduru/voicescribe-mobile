import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  FlatList,
  TouchableOpacity,
  Alert,
  TextInput,
  Modal,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { UserCircle, Plus, Mic, Trash2, Edit, Volume2 } from 'lucide-react-native';
import { useColors } from '../../../../shared/theme';
import { spacing, fontSize, borderRadius } from '../../../../shared/theme/tokens';
import { GlassCard } from '../../../../shared/components/GlassCard';
import { ToggleSwitch } from '../../../../shared/components/ToggleSwitch';
import { GlowButton } from '../../../../shared/components/GlowButton';
import { ScreenHeader } from '../../../../shared/components/ScreenHeader';
import { useTranslation } from '../../../../shared/i18n';
import type { SpeakerProfile } from '../../../../shared/types';

interface Speaker extends SpeakerProfile {
  recordings: number;
  lastUsed: string;
  hasVoiceSample: boolean;
}

export const SpeakerScreen: React.FC = () => {
  const colors = useColors();
  const t = useTranslation();
  
  const [speakerRecognition, setSpeakerRecognition] = useState(true);
  const [speakers, setSpeakers] = useState<Speaker[]>([
    { 
      id: '1', 
      name: 'Konuşmacı 1', 
      embedding: [], 
      createdAt: new Date().toISOString(), 
      recordings: 0, 
      lastUsed: '', 
      hasVoiceSample: false 
    },
  ]);
  const [modalVisible, setModalVisible] = useState(false);
  const [inputName, setInputName] = useState('');
  const [editingSpeaker, setEditingSpeaker] = useState<Speaker | null>(null);

  // Get speaker color based on ID
  const getSpeakerColor = (id: string) => {
    const speakerColors = [
      colors.speakerBlue,
      colors.speakerPink,
      colors.speakerGreen,
      colors.speakerOrange,
      colors.speakerPurple,
    ];
    const index = parseInt(id.replace(/\D/g, ''), 10) % speakerColors.length;
    return speakerColors[index];
  };

  // Add new speaker
  const addNewSpeaker = () => {
    if (inputName.trim() === '') {
      Alert.alert('Hata', 'Lütfen bir isim girin');
      return;
    }
    
    const newSpeaker: Speaker = {
      id: `speaker_${Date.now()}`,
      name: inputName.trim(),
      embedding: [],
      createdAt: new Date().toISOString(),
      recordings: 0,
      lastUsed: '',
      hasVoiceSample: false,
    };
    
    setSpeakers([...speakers, newSpeaker]);
    setInputName('');
    setModalVisible(false);
  };

  // Edit speaker
  const editSpeaker = () => {
    if (!editingSpeaker || inputName.trim() === '') {
      Alert.alert('Hata', 'Lütfen bir isim girin');
      return;
    }
    
    setSpeakers(speakers.map(s => 
      s.id === editingSpeaker.id ? { ...s, name: inputName.trim() } : s
    ));
    
    setInputName('');
    setEditingSpeaker(null);
    setModalVisible(false);
  };

  // Delete speaker
  const deleteSpeaker = (id: string) => {
    Alert.alert(
      'Konuşmacıyı Sil',
      'Bu konuşmacıyı silmek istediğinize emin misiniz?',
      [
        { text: 'İptal', style: 'cancel' },
        { 
          text: 'Sil', 
          style: 'destructive',
          onPress: () => {
            setSpeakers(speakers.filter(s => s.id !== id));
          }
        },
      ]
    );
  };

  // Record voice sample
  const recordVoiceSample = (id: string) => {
    // TODO: Implement actual voice recording functionality
    Alert.alert('Bilgi', 'Ses örneği kaydı yapılacak');
  };

  // Render speaker card
  const renderSpeakerCard = ({ item }: { item: Speaker }) => {
    const speakerColor = getSpeakerColor(item.id);
    
    return (
      <GlassCard style={styles.speakerCard}>
        <View style={styles.speakerHeader}>
          <View style={[styles.avatar, { backgroundColor: speakerColor }]}>
            <UserCircle size={32} color={colors.white} />
          </View>
          
          <View style={styles.speakerInfo}>
            <Text style={[styles.speakerName, { color: colors.text }]}>{item.name}</Text>
            <Text style={[styles.speakerMeta, { color: colors.textSecondary }]}>
              {item.recordings} kayıt • Son: {item.lastUsed || 'Henüz yok'}
            </Text>
          </View>
          
          <View style={styles.speakerActions}>
            <TouchableOpacity 
              style={styles.actionButton}
              onPress={() => {
                setEditingSpeaker(item);
                setInputName(item.name);
                setModalVisible(true);
              }}
            >
              <Edit size={20} color={colors.textSecondary} />
            </TouchableOpacity>
            <TouchableOpacity 
              style={styles.actionButton}
              onPress={() => deleteSpeaker(item.id)}
            >
              <Trash2 size={20} color={colors.error} />
            </TouchableOpacity>
          </View>
        </View>
        
        <View style={[styles.voiceSampleSection, { borderTopColor: colors.border }]}>
          <View style={styles.voiceSampleStatus}>
            {item.hasVoiceSample ? (
              <View style={styles.voiceSampleStatusContainer}>
                <Mic size={16} color={colors.success} />
                <Text style={[styles.voiceSampleText, { color: colors.success }]}>
                  Ses örneği mevcut
                </Text>
              </View>
            ) : (
              <TouchableOpacity 
                style={styles.voiceSampleButton}
                onPress={() => recordVoiceSample(item.id)}
              >
                <Mic size={16} color={colors.primary} />
                <Text style={[styles.voiceSampleText, { color: colors.primary }]}>
                  Ses örneği kaydet
                </Text>
              </TouchableOpacity>
            )}
          </View>
          
          {item.hasVoiceSample && (
            <>
              <View style={[styles.divider, { backgroundColor: colors.border }]} />
              
              <View style={styles.sampleHeader}>
                <Text style={[styles.sampleHeaderText, { color: colors.text }]}>
                  Ses Örneği
                </Text>
                <TouchableOpacity style={styles.listenButton}>
                  <Volume2 size={16} color={colors.primary} />
                  <Text style={[styles.listenButtonText, { color: colors.primary }]}>
                    Dinle
                  </Text>
                </TouchableOpacity>
              </View>
              
              <View style={[styles.waveformContainer, { backgroundColor: colors.surfaceContainerLow }]}>
                {Array.from({ length: 40 }).map((_, index) => (
                  <View 
                    key={index} 
                    style={[
                      styles.waveformBar, 
                      { 
                        height: Math.random() * 30 + 10, 
                        backgroundColor: colors.textMuted 
                      }
                    ]} 
                  />
                ))}
              </View>
            </>
          )}
        </View>
      </GlassCard>
    );
  };

  // Render empty state
  const renderEmptyState = () => (
    <View style={styles.emptyContainer}>
      <GlassCard intensity="medium" padding="lg" style={styles.emptyState}>
        <Text style={styles.icon}>🎙️</Text>
        <Text style={[styles.emptyTitle, { color: colors.text }]}>Hiç Konuşmacı Yok</Text>
        <Text style={[styles.emptyDesc, { color: colors.textSecondary }]}>
          Konuşmacı tanımayı kullanabilmek için ilk konuşmacınızı ekleyin.
        </Text>
      </GlassCard>
    </View>
  );

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]} edges={['top']}>
      {/* Sticky Header */}
      <View style={[styles.header, { backgroundColor: colors.background }]}>
        <ScreenHeader title={t.speaker} />
        
        {/* Speaker Recognition Card */}
        <GlassCard style={[styles.recognitionCard, { backgroundColor: colors.primaryContainer, borderColor: colors.primaryLight }]}>
          <View style={styles.recognitionHeader}>
            <Volume2 size={24} color={colors.primary} />
            <Text style={[styles.recognitionTitle, { color: colors.text }]}>
              Konuşmacı Tanıma
            </Text>
            <ToggleSwitch 
              value={speakerRecognition} 
              onValueChange={setSpeakerRecognition} 
            />
          </View>
          
          <Text style={[styles.recognitionDescription, { color: colors.textSecondary }]}>
            Kayıtlardaki konuşmacıları otomatik olarak tanımla ve etiketle
          </Text>
        </GlassCard>
        
        {/* Add Speaker Button */}
        <GlowButton
          title="Yeni Konuşmacı Ekle"
          variant="primary"
          icon={<Plus size={20} color={colors.white} />}
          onPress={() => {
            setEditingSpeaker(null);
            setInputName('');
            setModalVisible(true);
          }}
          style={styles.addButton}
        />
      </View>

      {/* Speakers List */}
      {speakers.length === 0 ? (
        renderEmptyState()
      ) : (
        <>
          <View style={styles.sectionHeader}>
            <Text style={[styles.sectionTitle, { color: colors.text }]}>
              Kayıtlı Konuşmacılar ({speakers.length})
            </Text>
          </View>
          
          <FlatList
            data={speakers}
            renderItem={renderSpeakerCard}
            keyExtractor={item => item.id}
            contentContainerStyle={styles.listContent}
            showsVerticalScrollIndicator={false}
          />
        </>
      )}

      {/* Speaker Match History Card */}
      <GlassCard style={[styles.historyCard, { backgroundColor: colors.infoLight, borderColor: colors.info }]}>
        <View style={styles.historyHeader}>
          <Volume2 size={24} color={colors.info} />
          <Text style={[styles.historyTitle, { color: colors.text }]}>
            Konuşmacı Eşleşme Geçmişi
          </Text>
        </View>
        
        <Text style={[styles.historyDescription, { color: colors.textSecondary }]}>
          Son 30 kayıtta 156 konuşmacı eşleşmesi yapıldı
        </Text>
        
        <View style={styles.statsContainer}>
          <View style={styles.statItem}>
            <Text style={[styles.statLabel, { color: colors.textSecondary }]}>
              Başarılı eşleşme
            </Text>
            <Text style={[styles.statValue, { color: colors.text }]}>
              142 (%91)
            </Text>
          </View>
        </View>
        
        <View style={[styles.progressBar, { backgroundColor: colors.surfaceContainerLow }]}>
          <View style={[styles.progressFill, { backgroundColor: colors.info, width: '91%' }]} />
        </View>
      </GlassCard>

      {/* Modal for adding/editing speakers */}
      <Modal
        visible={modalVisible}
        transparent={true}
        animationType="fade"
        onRequestClose={() => setModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { backgroundColor: colors.surface }]}>
            <Text style={[styles.modalTitle, { color: colors.text }]}>
              {editingSpeaker ? 'Konuşmacıyı Düzenle' : 'Yeni Konuşmacı Ekle'}
            </Text>
            
            <TextInput
              value={inputName}
              onChangeText={setInputName}
              placeholder="Konuşmacı adı"
              placeholderTextColor={colors.textMuted}
              style={[styles.input, { 
                backgroundColor: colors.surfaceContainerLow,
                color: colors.text,
                borderColor: colors.border
              }]}
              autoFocus
            />
            
            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.cancelButton, { backgroundColor: colors.surfaceContainerLow }]}
                onPress={() => {
                  setModalVisible(false);
                  setEditingSpeaker(null);
                  setInputName('');
                }}
              >
                <Text style={[styles.modalButtonText, { color: colors.textSecondary }]}>
                  İptal
                </Text>
              </TouchableOpacity>
              
              <TouchableOpacity
                style={[styles.modalButton, styles.confirmButton, { backgroundColor: colors.primary }]}
                onPress={editingSpeaker ? editSpeaker : addNewSpeaker}
              >
                <Text style={[styles.modalButtonText, { color: colors.textOnPrimary }]}>
                  {editingSpeaker ? 'Güncelle' : 'Ekle'}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.md,
    paddingBottom: spacing.md,
  },
  headerTitle: {
    fontSize: fontSize.heading,
    fontWeight: '700',
    marginBottom: spacing.md,
  },
  recognitionCard: {
    marginBottom: spacing.md,
  },
  recognitionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.xs,
  },
  recognitionTitle: {
    fontSize: fontSize.lg,
    fontWeight: '600',
    flex: 1,
  },
  recognitionDescription: {
    fontSize: fontSize.sm,
  },
  addButton: {
    width: '100%',
    marginVertical: spacing.md,
  },
  sectionHeader: {
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
  },
  sectionTitle: {
    fontSize: fontSize.lg,
    fontWeight: '600',
  },
  listContent: {
    padding: spacing.lg,
    paddingBottom: spacing.md,
  },
  speakerCard: {
    marginBottom: spacing.md,
  },
  speakerHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.full,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  speakerInfo: {
    flex: 1,
  },
  speakerName: {
    fontSize: fontSize.md,
    fontWeight: '500',
  },
  speakerMeta: {
    fontSize: fontSize.xs,
    marginTop: spacing.xs,
  },
  speakerActions: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  actionButton: {
    padding: spacing.xs,
  },
  voiceSampleSection: {
    borderTopWidth: 1,
    paddingTop: spacing.md,
  },
  voiceSampleStatus: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  voiceSampleStatusContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  voiceSampleButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  voiceSampleText: {
    fontSize: fontSize.sm,
    fontWeight: '500',
  },
  divider: {
    height: 1,
    marginVertical: spacing.md,
  },
  sampleHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  sampleHeaderText: {
    fontSize: fontSize.sm,
    fontWeight: '500',
  },
  listenButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  listenButtonText: {
    fontSize: fontSize.sm,
    fontWeight: '500',
  },
  waveformContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-around',
    height: 50,
    borderRadius: borderRadius.sm,
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
  },
  waveformBar: {
    width: 4,
    borderRadius: 2,
  },
  historyCard: {
    margin: spacing.lg,
    marginTop: spacing.xs,
  },
  historyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.xs,
  },
  historyTitle: {
    fontSize: fontSize.lg,
    fontWeight: '600',
    flex: 1,
  },
  historyDescription: {
    fontSize: fontSize.sm,
    marginBottom: spacing.sm,
  },
  statsContainer: {
    marginBottom: spacing.sm,
  },
  statItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: spacing.xs,
  },
  statLabel: {
    fontSize: fontSize.sm,
  },
  statValue: {
    fontSize: fontSize.sm,
    fontWeight: '500',
  },
  progressBar: {
    height: 8,
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: 4,
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
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    width: '80%',
    maxWidth: 400,
    borderRadius: borderRadius.lg,
    padding: spacing.lg,
    elevation: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
  },
  modalTitle: {
    fontSize: fontSize.lg,
    fontWeight: '600',
    marginBottom: spacing.md,
    textAlign: 'center',
  },
  input: {
    borderWidth: 1,
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    fontSize: fontSize.md,
    marginBottom: spacing.lg,
  },
  modalButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: spacing.sm,
  },
  modalButton: {
    flex: 1,
    padding: spacing.md,
    borderRadius: borderRadius.md,
    alignItems: 'center',
  },
  cancelButton: {
    // backgroundColor handled via inline style
  },
  confirmButton: {
    // backgroundColor handled via inline style
  },
  modalButtonText: {
    fontSize: fontSize.md,
    fontWeight: '500',
  },
});
