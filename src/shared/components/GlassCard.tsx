import React from 'react';
import { View, ViewProps, ViewStyle } from 'react-native';
import { useColors } from '../theme';
import { borderRadius, spacing } from '../theme/tokens';

interface CardProps extends ViewProps {
  intensity?: 'low' | 'medium' | 'high'; // kept for backward compat
  padding?: 'sm' | 'md' | 'lg' | 'xl';
}

export const GlassCard = ({ children, style, intensity = 'medium', padding = 'lg', ...rest }: CardProps) => {
  const colors = useColors();

  return (
    <View
      style={[
        {
          backgroundColor: colors.surface,
          borderRadius: borderRadius.lg,
          borderWidth: 1,
          borderColor: colors.border,
          padding: spacing[padding],
          // Subtle shadow
          shadowColor: '#000',
          shadowOffset: { width: 0, height: 1 },
          shadowOpacity: 0.05,
          shadowRadius: 3,
          elevation: 1,
        },
        style,
      ]}
      {...rest}
    >
      {children}
    </View>
  );
};
