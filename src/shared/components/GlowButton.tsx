import React from 'react';
import { TouchableOpacity, Text, StyleSheet, TouchableOpacityProps, StyleProp, ViewStyle, TextStyle } from 'react-native';
import { colors, borderRadius, spacing, fontSize, fontWeight } from '../theme';

interface GlowButtonProps extends TouchableOpacityProps {
  title: string;
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  buttonStyle?: StyleProp<ViewStyle>;
  textStyle?: StyleProp<TextStyle>;
}

export const GlowButton = ({
  title,
  variant = 'primary',
  size = 'md',
  buttonStyle,
  textStyle,
  ...rest
}: GlowButtonProps) => {
  const getVariantStyles = () => {
    switch(variant) {
      case 'danger':
        return {
          bg: colors.errorContainer,
          text: colors.error,
          shadow: colors.error
        };
      case 'secondary':
        return {
          bg: colors.surfaceContainerHigh,
          text: colors.text,
          shadow: colors.transparent
        };
      default:
        return {
          bg: colors.primaryContainer,
          text: colors.white,
          shadow: colors.primary
        };
    }
  };

  const getSizeStyles = () => {
    switch(size) {
      case 'sm': return { paddingVertical: spacing.sm, paddingHorizontal: spacing.md, fontSize: fontSize.sm };
      case 'lg': return { paddingVertical: spacing.lg, paddingHorizontal: spacing.xl, fontSize: fontSize.lg };
      default: return { paddingVertical: spacing.md, paddingHorizontal: spacing.lg, fontSize: fontSize.md };
    }
  };

  const vStyles = getVariantStyles();
  const sStyles = getSizeStyles();

  return (
    <TouchableOpacity
      style={[
        styles.button,
        {
          backgroundColor: vStyles.bg,
          paddingVertical: sStyles.paddingVertical,
          paddingHorizontal: sStyles.paddingHorizontal,
          shadowColor: vStyles.shadow,
        },
        buttonStyle
      ]}
      {...rest}
    >
      <Text style={[styles.text, { color: vStyles.text, fontSize: sStyles.fontSize }, textStyle]}>
        {title}
      </Text>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  button: {
    borderRadius: borderRadius.full,
    alignItems: 'center',
    justifyContent: 'center',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.3,
    shadowRadius: 16,
    elevation: 8, // For android
    borderWidth: 1,
    borderColor: colors.border,
  },
  text: {
    fontFamily: 'sans-serif-medium',
    fontWeight: fontWeight.bold,
  }
});
