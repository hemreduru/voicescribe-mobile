import React, { useState } from 'react';
import { StyleSheet, Text, View, ScrollView } from 'react-native';
import { colors, fontSize, spacing, borderRadius } from '../../../../shared/theme';
import { GlassCard } from '../../../../shared/components/GlassCard';
import { GlowButton } from '../../../../shared/components/GlowButton';

export const SummaryScreen: React.FC = () => {
  const [modelType, setModelType] = useState<'local' | 'cloud'>('local');

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>AI Notes</Text>
        <Text style={styles.subtitle}>Intelligent Distillation</Text>
      </View>

      <View style={styles.toggleWrapper}>
        <GlassCard intensity="low" padding="sm" style={styles.segmentedControl}>
          <GlowButton 
            title="Local Engine" 
            variant={modelType === 'local' ? 'primary' : 'secondary'}
            size="sm"
            onPress={() => setModelType('local')}
            buttonStyle={styles.segmentBtn}
          />
          <GlowButton 
            title="Cloud LLM" 
            variant={modelType === 'cloud' ? 'primary' : 'secondary'}
            size="sm"
            onPress={() => setModelType('cloud')}
            buttonStyle={styles.segmentBtn}
          />
        </GlassCard>
      </View>

      <ScrollView contentContainerStyle={styles.content}>
         <GlassCard intensity="medium" padding="lg" style={styles.emptyState}>
            <Text style={styles.icon}>✨</Text>
            <Text style={styles.emptyTitle}>No transcript selected</Text>
            <Text style={styles.emptyDesc}>
              Select a session from the Vault to generate an AI summary, action items, and structural notes.
            </Text>
            <GlowButton title="Generate Summary" variant="primary" style={styles.cta} disabled />
         </GlassCard>
      </ScrollView>
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
    paddingBottom: spacing.lg,
    paddingHorizontal: spacing.lg,
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
    color: colors.secondary,
    marginTop: spacing.xs,
  },
  toggleWrapper: {
    paddingHorizontal: spacing.lg,
    marginBottom: spacing.md,
  },
  segmentedControl: {
    flexDirection: 'row',
    borderRadius: borderRadius.full,
    justifyContent: 'space-between',
  },
  segmentBtn: {
    flex: 1,
    marginHorizontal: 2,
    elevation: 0,
    shadowOpacity: 0,
  },
  content: {
    paddingHorizontal: spacing.lg,
    paddingBottom: 100,
  },
  emptyState: {
    alignItems: 'center',
    marginTop: spacing.xl,
  },
  icon: {
    fontSize: 48,
    marginBottom: spacing.md,
  },
  emptyTitle: {
    fontFamily: 'sans-serif-medium',
    fontSize: fontSize.xl,
    color: colors.text,
    marginBottom: spacing.sm,
  },
  emptyDesc: {
    fontFamily: 'sans-serif',
    fontSize: fontSize.md,
    color: colors.textSecondary,
    textAlign: 'center',
    lineHeight: 22,
    marginBottom: spacing.xl,
  },
  cta: {
    width: '100%',
    opacity: 0.5,
  }
});

