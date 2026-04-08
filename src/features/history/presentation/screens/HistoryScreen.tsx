import React from 'react';
import { StyleSheet, Text, View, ScrollView } from 'react-native';
import { colors, fontSize, spacing } from '../../../../shared/theme';
import { GlassCard } from '../../../../shared/components/GlassCard';

export const HistoryScreen: React.FC = () => {
  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>The Vault</Text>
        <Text style={styles.subtitle}>
          Secure local audio and summaries
        </Text>
      </View>

      <ScrollView contentContainerStyle={styles.content}>
         <GlassCard intensity="medium" padding="lg" style={styles.emptyState}>
            <Text style={styles.icon}>🗄️</Text>
            <Text style={styles.emptyTitle}>Vault is secure and empty</Text>
            <Text style={styles.emptyDesc}>
              Past recordings, full audio tracks, and AI summaries will be stored safely on-device here.
            </Text>
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
    color: colors.textSecondary,
    marginTop: spacing.xs,
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
  },
});

