import React from 'react';
import { StyleSheet, Text, View, ScrollView } from 'react-native';
import { colors, fontSize, spacing } from '../../../../shared/theme';
import { GlassCard } from '../../../../shared/components/GlassCard';
import { GlowButton } from '../../../../shared/components/GlowButton';

export const SpeakerScreen: React.FC = () => {
  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Voice ID</Text>
        <Text style={styles.subtitle}>
          Acoustic Profile Management
        </Text>
      </View>

      <ScrollView contentContainerStyle={styles.content}>
         <GlassCard intensity="medium" padding="lg" style={styles.emptyState}>
            <Text style={styles.icon}>🎙️</Text>
            <Text style={styles.emptyTitle}>No Voices Enrolled</Text>
            <Text style={styles.emptyDesc}>
              Enroll your voice or team members to allow the AI to automatically identify who is speaking.
            </Text>
            
            <GlowButton 
              title="Enroll New Voice" 
              variant="primary" 
              style={styles.cta} 
            />
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
    marginBottom: spacing.xl,
  },
  cta: {
    width: '100%',
  }
});

