import React from 'react';
import { TouchableOpacity, Text, TouchableOpacityProps, StyleProp, ViewStyle, TextStyle } from 'react-native';
import { useColors } from '../theme';
import { borderRadius, spacing, fontSize, fontWeight } from '../theme/tokens';

interface ButtonProps extends TouchableOpacityProps {
  title: string;
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  icon?: React.ReactNode; // For lucide icons
  buttonStyle?: StyleProp<ViewStyle>;
  textStyle?: StyleProp<TextStyle>;
}

export const GlowButton = ({ title, variant = 'primary', size = 'md', icon, buttonStyle, textStyle, disabled, ...rest }: ButtonProps) => {
  const colors = useColors();

  const getVariantStyles = () => {
    switch (variant) {
      case 'danger':
        return { bg: colors.error, text: colors.white };
      case 'secondary':
        return { bg: colors.surfaceSecondary, text: colors.text };
      default:
        return { bg: colors.primary, text: colors.textOnPrimary };
    }
  };

  const getSizeStyles = () => {
    switch (size) {
      case 'sm': return { py: spacing.sm, px: spacing.md, fs: fontSize.sm };
      case 'lg': return { py: spacing.lg, px: spacing.xl, fs: fontSize.lg };
      default: return { py: spacing.md, px: spacing.lg, fs: fontSize.md };
    }
  };

  const v = getVariantStyles();
  const s = getSizeStyles();

  return (
    <TouchableOpacity
      style={[
        {
          backgroundColor: v.bg,
          paddingVertical: s.py,
          paddingHorizontal: s.px,
          borderRadius: borderRadius.lg,
          flexDirection: 'row',
          alignItems: 'center',
          justifyContent: 'center',
          gap: spacing.sm,
          opacity: disabled ? 0.5 : 1,
        },
        buttonStyle,
      ]}
      disabled={disabled}
      activeOpacity={0.7}
      {...rest}
    >
      {icon}
      <Text style={[{ color: v.text, fontSize: s.fs, fontWeight: fontWeight.medium }, textStyle]}>
        {title}
      </Text>
    </TouchableOpacity>
  );
};
