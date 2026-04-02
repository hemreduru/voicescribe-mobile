export const colors = {
  primary: '#6C63FF',
  primaryDark: '#5A52E0',
  primaryLight: '#8B85FF',

  secondary: '#FF6584',
  secondaryDark: '#E05570',
  secondaryLight: '#FF8DA0',

  background: '#0F0F1A',
  surface: '#1A1A2E',
  surfaceLight: '#252540',
  card: '#16213E',

  text: '#EAEAEA',
  textSecondary: '#A0A0B8',
  textMuted: '#6B6B80',

  success: '#4ADE80',
  warning: '#FBBF24',
  error: '#F87171',
  info: '#60A5FA',

  border: '#2A2A40',
  divider: '#1E1E35',

  white: '#FFFFFF',
  black: '#000000',
  transparent: 'transparent',
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
} as const;

export const borderRadius = {
  sm: 6,
  md: 12,
  lg: 16,
  xl: 24,
  full: 9999,
} as const;

export const fontSize = {
  xs: 10,
  sm: 12,
  md: 14,
  lg: 16,
  xl: 20,
  xxl: 24,
  heading: 32,
} as const;

export const fontWeight = {
  regular: '400' as const,
  medium: '500' as const,
  semibold: '600' as const,
  bold: '700' as const,
};

export type Colors = typeof colors;
export type Spacing = typeof spacing;
