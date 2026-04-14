import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  RefreshCw,
  Copy,
  Download,
  Sparkles,
  Cloud,
  HardDrive,
} from 'lucide-react-native';
import { useColors } from '../../../../shared/theme';
import { spacing, borderRadius, fontSize, fontWeight } from '../../../../shared/theme/tokens';
import { GlassCard } from '../../../../shared/components/GlassCard';
import { GlowButton } from '../../../../shared/components/GlowButton';
import { useSummaryStore } from '../../../../shared/stores';

type SummaryLength = 'short' | 'medium' | 'long';
type ModelType = 'local' | 'cloud';

export const SummaryScreen: React.FC = () => {
  const colors = useColors();
  const [modelType, setModelType] = useState<ModelType>('local');
  const [summaryLength, setSummaryLength] = useState<SummaryLength>('medium');
  const [isGenerating, setIsGenerating] = useState(false);
  const [progress, setProgress] = useState(0);

  // Get summary from store (if available)
  const currentSummary = useSummaryStore((state) => state.currentSummary);
  const isStoreGenerating = useSummaryStore((state) => state.isGenerating);

  const handleRegenerate = () => {
    setIsGenerating(true);
    setProgress(0);
    // Simulate generation progress
    const interval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(interval);
          setIsGenerating(false);
          return 100;
        }
        return prev + 10;
      });
    }, 200);
  };

  const handleCopy = () => {
    console.log('Copy summary');
  };

  const handleExport = () => {
    console.log('Export summary');
  };

  const getLengthLabel = (length: SummaryLength): string => {
    switch (length) {
      case 'short':
        return 'Kısa';
      case 'medium':
        return 'Orta';
      case 'long':
        return 'Uzun';
      default:
        return 'Orta';
    }
  };

  const getProviderLabel = (type: ModelType): string => {
    return type === 'local' ? 'Yerel AI' : 'Cloud AI';
  };

  // Loading State
  if (isGenerating || isStoreGenerating) {
    return (
      <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]} edges={['top']}>
        <View style={styles.loadingContainer}>
          <Sparkles size={48} color={colors.primary} />
          <Text style={[styles.loadingText, { color: colors.text }]}>
            AI özet oluşturuyor...
          </Text>
          <View style={[styles.progressBarContainer, { backgroundColor: colors.surfaceSecondary }]}>
            <View
              style={[
                styles.progressBar,
                { backgroundColor: colors.primary, width: `${progress}%` },
              ]}
            />
          </View>
        </View>
      </SafeAreaView>
    );
  }

  // Empty State
  if (!currentSummary) {
    return (
      <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]} edges={['top']}>
        {/* Sticky Header */}
        <View style={[styles.stickyHeader, { backgroundColor: colors.background, borderBottomColor: colors.border }]}>
          <Text style={[styles.headerTitle, { color: colors.text }]}>Özet</Text>

          {/* Local/Cloud Toggle */}
          <View style={styles.toggleContainer}>
            <TouchableOpacity
              style={[
                styles.toggleButton,
                modelType === 'local'
                  ? { backgroundColor: colors.primary }
                  : { backgroundColor: colors.surfaceSecondary },
              ]}
              onPress={() => setModelType('local')}
            >
              <HardDrive
                size={16}
                color={modelType === 'local' ? colors.textOnPrimary : colors.textSecondary}
              />
              <Text
                style={[
                  styles.toggleButtonText,
                  modelType === 'local'
                    ? { color: colors.textOnPrimary }
                    : { color: colors.textSecondary },
                ]}
              >
                Yerel
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.toggleButton,
                modelType === 'cloud'
                  ? { backgroundColor: colors.primary }
                  : { backgroundColor: colors.surfaceSecondary },
              ]}
              onPress={() => setModelType('cloud')}
            >
              <Cloud
                size={16}
                color={modelType === 'cloud' ? colors.textOnPrimary : colors.textSecondary}
              />
              <Text
                style={[
                  styles.toggleButtonText,
                  modelType === 'cloud'
                    ? { color: colors.textOnPrimary }
                    : { color: colors.textSecondary },
                ]}
              >
                Cloud
              </Text>
            </TouchableOpacity>
          </View>

          {/* Summary Length Selector */}
          <View style={styles.lengthSelector}>
            {(['short', 'medium', 'long'] as SummaryLength[]).map((length) => (
              <TouchableOpacity
                key={length}
                style={[
                  styles.lengthButton,
                  summaryLength === length
                    ? { backgroundColor: colors.primary }
                    : { backgroundColor: colors.surfaceSecondary },
                ]}
                onPress={() => setSummaryLength(length)}
              >
                <Text
                  style={[
                    styles.lengthButtonText,
                    summaryLength === length
                      ? { color: colors.textOnPrimary }
                      : { color: colors.textSecondary },
                  ]}
                >
                  {getLengthLabel(length)}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          {/* Action Buttons */}
          <View style={styles.actionButtonsRow}>
            <TouchableOpacity style={styles.actionButton} onPress={handleRegenerate}>
              <RefreshCw size={20} color={colors.primary} />
              <Text style={[styles.actionButtonText, { color: colors.primary }]}>
                Yeniden Oluştur
              </Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionButton} onPress={handleCopy}>
              <Copy size={20} color={colors.textSecondary} />
              <Text style={[styles.actionButtonText, { color: colors.textSecondary }]}>
                Kopyala
              </Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionButton} onPress={handleExport}>
              <Download size={20} color={colors.textSecondary} />
              <Text style={[styles.actionButtonText, { color: colors.textSecondary }]}>
                Dışa Aktar
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        <ScrollView contentContainerStyle={styles.content}>
          <GlassCard style={styles.emptyState}>
            <Text style={styles.icon}>✨</Text>
            <Text style={[styles.emptyTitle, { color: colors.text }]}>
              No transcript selected
            </Text>
            <Text style={[styles.emptyDesc, { color: colors.textSecondary }]}>
              Select a session from the Vault to generate an AI summary, action items, and structural notes.
            </Text>
            <GlowButton
              title="Generate Summary"
              variant="primary"
              style={styles.cta}
              disabled
            />
          </GlassCard>
        </ScrollView>
      </SafeAreaView>
    );
  }

  // Summary Content View
  return (
    <SafeAreaView style={[styles.container, { backgroundColor: colors.background }]} edges={['top']}>
      {/* Sticky Header */}
      <View style={[styles.stickyHeader, { backgroundColor: colors.background, borderBottomColor: colors.border }]}>
        <Text style={[styles.headerTitle, { color: colors.text }]}>Özet</Text>

        {/* Local/Cloud Toggle */}
        <View style={styles.toggleContainer}>
          <TouchableOpacity
            style={[
              styles.toggleButton,
              modelType === 'local'
                ? { backgroundColor: colors.primary }
                : { backgroundColor: colors.surfaceSecondary },
            ]}
            onPress={() => setModelType('local')}
          >
            <HardDrive
              size={16}
              color={modelType === 'local' ? colors.textOnPrimary : colors.textSecondary}
            />
            <Text
              style={[
                styles.toggleButtonText,
                modelType === 'local'
                  ? { color: colors.textOnPrimary }
                  : { color: colors.textSecondary },
              ]}
            >
              Yerel
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[
              styles.toggleButton,
              modelType === 'cloud'
                ? { backgroundColor: colors.primary }
                : { backgroundColor: colors.surfaceSecondary },
            ]}
            onPress={() => setModelType('cloud')}
          >
            <Cloud
              size={16}
              color={modelType === 'cloud' ? colors.textOnPrimary : colors.textSecondary}
            />
            <Text
              style={[
                styles.toggleButtonText,
                modelType === 'cloud'
                  ? { color: colors.textOnPrimary }
                  : { color: colors.textSecondary },
              ]}
            >
              Cloud
            </Text>
          </TouchableOpacity>
        </View>

        {/* Summary Length Selector */}
        <View style={styles.lengthSelector}>
          {(['short', 'medium', 'long'] as SummaryLength[]).map((length) => (
            <TouchableOpacity
              key={length}
              style={[
                styles.lengthButton,
                summaryLength === length
                  ? { backgroundColor: colors.primary }
                  : { backgroundColor: colors.surfaceSecondary },
              ]}
              onPress={() => setSummaryLength(length)}
            >
              <Text
                style={[
                  styles.lengthButtonText,
                  summaryLength === length
                    ? { color: colors.textOnPrimary }
                    : { color: colors.textSecondary },
                ]}
              >
                {getLengthLabel(length)}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Action Buttons */}
        <View style={styles.actionButtonsRow}>
          <TouchableOpacity style={styles.actionButton} onPress={handleRegenerate}>
            <RefreshCw size={20} color={colors.primary} />
            <Text style={[styles.actionButtonText, { color: colors.primary }]}>
              Yeniden Oluştur
            </Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionButton} onPress={handleCopy}>
            <Copy size={20} color={colors.textSecondary} />
            <Text style={[styles.actionButtonText, { color: colors.textSecondary }]}>
              Kopyala
            </Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionButton} onPress={handleExport}>
            <Download size={20} color={colors.textSecondary} />
            <Text style={[styles.actionButtonText, { color: colors.textSecondary }]}>
              Dışa Aktar
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        {/* AI Badge Card */}
        <View style={[styles.aiBadgeCard, { backgroundColor: colors.primaryContainer, borderColor: colors.border }]}>
          <View style={styles.aiBadgeHeader}>
            <Sparkles size={20} color={colors.primary} />
            <Text style={[styles.aiBadgeText, { color: colors.primary }]}>AI Özeti</Text>
          </View>
          <View style={styles.aiBadgeInfo}>
            <View style={styles.aiBadgeInfoItem}>
              <Text style={[styles.aiBadgeInfoLabel, { color: colors.textSecondary }]}>
                Sağlayıcı
              </Text>
              <Text style={[styles.aiBadgeInfoValue, { color: colors.text }]}>
                {getProviderLabel(modelType)}
              </Text>
            </View>
            <View style={styles.aiBadgeInfoItem}>
              <Text style={[styles.aiBadgeInfoLabel, { color: colors.textSecondary }]}>
                Uzunluk
              </Text>
              <Text style={[styles.aiBadgeInfoValue, { color: colors.text }]}>
                {getLengthLabel(summaryLength)}
              </Text>
            </View>
          </View>
        </View>

        {/* Summary Content */}
        <GlassCard style={styles.summaryCard}>
          <Text style={[styles.summaryText, { color: colors.text }]}>
            {currentSummary.summaryText}
          </Text>
        </GlassCard>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
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
  // Toggle Container
  toggleContainer: {
    flexDirection: 'row',
    marginBottom: spacing.md,
    gap: spacing.sm,
  },
  toggleButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.xs,
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
    borderRadius: borderRadius.lg,
  },
  toggleButtonText: {
    fontSize: fontSize.sm,
    fontWeight: fontWeight.medium,
  },
  // Length Selector
  lengthSelector: {
    flexDirection: 'row',
    marginBottom: spacing.md,
    gap: spacing.sm,
  },
  lengthButton: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
    borderRadius: borderRadius.lg,
  },
  lengthButtonText: {
    fontSize: fontSize.sm,
    fontWeight: fontWeight.medium,
  },
  // Action Buttons
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
  // Content
  content: {
    paddingHorizontal: spacing.lg,
    paddingBottom: 100,
  },
  // Loading State
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: spacing.xl,
  },
  loadingText: {
    fontSize: fontSize.lg,
    fontWeight: '600',
    marginTop: spacing.md,
    marginBottom: spacing.lg,
  },
  progressBarContainer: {
    width: '80%',
    height: 8,
    borderRadius: borderRadius.full,
    overflow: 'hidden',
  },
  progressBar: {
    height: '100%',
    borderRadius: borderRadius.full,
  },
  // Empty State
  emptyState: {
    alignItems: 'center',
    marginTop: spacing.xl,
    padding: spacing.xl,
  },
  icon: {
    fontSize: 48,
    marginBottom: spacing.md,
  },
  emptyTitle: {
    fontSize: fontSize.xl,
    fontWeight: '600',
    marginBottom: spacing.sm,
  },
  emptyDesc: {
    fontSize: fontSize.md,
    textAlign: 'center',
    lineHeight: 22,
    marginBottom: spacing.xl,
  },
  cta: {
    width: '100%',
    opacity: 0.5,
  },
  // AI Badge Card
  aiBadgeCard: {
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    padding: spacing.md,
    marginBottom: spacing.lg,
    marginTop: spacing.md,
  },
  aiBadgeHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    marginBottom: spacing.md,
  },
  aiBadgeText: {
    fontSize: fontSize.md,
    fontWeight: '600',
  },
  aiBadgeInfo: {
    flexDirection: 'row',
    gap: spacing.lg,
  },
  aiBadgeInfoItem: {
    flex: 1,
  },
  aiBadgeInfoLabel: {
    fontSize: fontSize.xs,
    marginBottom: spacing.xs,
  },
  aiBadgeInfoValue: {
    fontSize: fontSize.sm,
    fontWeight: '600',
  },
  // Summary Card
  summaryCard: {
    marginTop: spacing.sm,
  },
  summaryText: {
    fontSize: fontSize.md,
    lineHeight: 24,
  },
});
