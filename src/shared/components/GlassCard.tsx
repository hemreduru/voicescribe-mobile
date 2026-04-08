import React from 'react';
import { View, StyleSheet, ViewProps } from 'react-native';
import { colors, borderRadius, spacing } from '../theme';

interface GlassCardProps extends ViewProps {
  intensity?: 'low' | 'medium' | 'high';
  padding?: keyof typeof spacing;
}

export const GlassCard = ({ 
  children, 
  style, 
  intensity = 'medium',
  padding = 'lg',
  ...rest 
}: GlassCardProps) => {
  const getBackgroundColor = () => {
    switch(intensity) {
      case 'low': return colors.surfaceContainerLow;
      case 'high': return colors.surfaceGlass;
      default: return colors.surfaceVariant;
    }
  };

  return (
    <View 
      style={[
        styles.container, 
        { 
          backgroundColor: getBackgroundColor(),
          padding: spacing[padding]
        },
        style
      ]} 
      {...rest}
    >
      {children}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: borderRadius.xl,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: colors.border,
  }
});
