import React from 'react';
import { View, Text } from 'react-native';
import { useColors } from '../theme';
import { spacing, fontSize, borderRadius } from '../theme/tokens';

interface BadgeProps {
  label: string;
  variant: 'sync' | 'transcript' | 'summary' | 'info' | 'warning' | 'error';
  icon?: React.ReactNode;
}

export const Badge: React.FC<BadgeProps> = ({ label, variant, icon }) => {
  const colors = useColors();

  const getVariantColors = () => {
    switch (variant) {
      case 'sync': return { bg: colors.syncBadgeBg, text: colors.syncBadgeText };
      case 'transcript': return { bg: colors.transcriptBadgeBg, text: colors.transcriptBadgeText };
      case 'summary': return { bg: colors.summaryBadgeBg, text: colors.summaryBadgeText };
      case 'info': return { bg: colors.infoLight, text: colors.infoText };
      case 'warning': return { bg: colors.warningLight, text: colors.warning };
      case 'error': return { bg: colors.errorLight, text: colors.errorText };
    }
  };

  const v = getVariantColors();

  return (
    <View style={{
      flexDirection: 'row',
      alignItems: 'center',
      gap: 4,
      paddingHorizontal: spacing.sm,
      paddingVertical: spacing.xs,
      backgroundColor: v.bg,
      borderRadius: borderRadius.sm,
    }}>
      {icon}
      <Text style={{ color: v.text, fontSize: fontSize.xs, fontWeight: '500' }}>{label}</Text>
    </View>
  );
};
