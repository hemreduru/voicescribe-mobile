export const colors = {
  // Brand
  primary: '#bac3ff',
  primaryContainer: '#3749ad',
  onPrimary: '#08218a',
  
  secondary: '#67d9c9',
  secondaryContainer: '#21a293',
  onSecondary: '#003731',
  
  tertiary: '#f9abff',
  tertiaryContainer: '#8c10a1',
  onTertiary: '#570066',

  // Surfaces (Deep Obsidian to Grey)
  background: '#0B0F19', // The deepest void
  surface: '#121416',
  surfaceContainerLow: '#1a1c1e',
  surfaceContainer: '#1e2022',
  surfaceContainerHigh: '#282a2c',
  surfaceContainerHighest: '#333537',
  
  surfaceVariant: 'rgba(51, 53, 55, 0.65)', // Glass effect fake
  surfaceGlass: 'rgba(26, 28, 30, 0.75)',

  // Text
  text: '#e2e2e5', // onSurface
  textSecondary: '#c5c5d5', // onSurfaceVariant
  textMuted: '#8f909f', // outline

  // Semantic
  success: '#21a293',
  warning: '#FBBF24',
  error: '#ffb4ab',
  errorContainer: '#93000a',

  // Structural
  border: 'rgba(255, 255, 255, 0.05)', // The "Ghost Border"
  divider: 'rgba(255, 255, 255, 0.03)',
  transparent: 'transparent',
  white: '#FFFFFF',
  black: '#000000',
  
  // Neon Glows
  glowPrimary: 'rgba(186, 195, 255, 0.2)',
  glowSecondary: 'rgba(103, 217, 201, 0.2)',
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
  display: 40,
} as const;

export const fontWeight = {
  regular: '400' as const,
  medium: '500' as const,
  semibold: '600' as const,
  bold: '700' as const,
};

export type Colors = typeof colors;
export type Spacing = typeof spacing;

