export const lightColors = {
  // Primary
  primary: '#db2777',        // pink-600
  primaryDark: '#e11d48',    // rose-600
  primaryLight: '#fce7f3',   // pink-100
  primaryContainer: '#fdf2f8', // pink-50
  
  // Secondary (for backward compatibility)
  secondary: '#ec4899',      // pink-500
  secondaryContainer: '#fce7f3', // pink-100
  onSecondary: '#831843',
  
  // Tertiary (for backward compatibility)
  tertiary: '#f472b6',
  tertiaryContainer: '#fce7f3',
  onTertiary: '#831843',
  
  // Background
  background: '#f9fafb',     // gray-50
  backgroundGradientStart: '#fdf2f8', // pink-50
  backgroundGradientEnd: '#fff1f2',   // rose-50
  
  // Surface
  surface: '#ffffff',
  surfaceSecondary: '#f3f4f6', // gray-100
  surfaceContainer: '#ffffff',
  surfaceContainerLow: '#f9fafb',
  surfaceContainerHigh: '#f3f4f6',
  surfaceContainerHighest: '#e5e7eb',
  surfaceVariant: '#f3f4f6',
  surfaceGlass: 'rgba(255, 255, 255, 0.8)',
  
  // Text
  text: '#111827',           // gray-900
  textSecondary: '#6b7280',  // gray-500
  textMuted: '#9ca3af',      // gray-400
  textOnPrimary: '#ffffff',
  onSurface: '#111827',
  onSurfaceVariant: '#6b7280',
  
  // Border
  border: '#e5e7eb',         // gray-200
  borderLight: '#f3f4f6',    // gray-100
  divider: '#e5e7eb',
  
  // Status
  success: '#16a34a',        // green-600
  successLight: '#dcfce7',   // green-100
  successText: '#15803d',    // green-700
  warning: '#eab308',        // yellow-500
  warningLight: '#fef9c3',   // yellow-100
  error: '#dc2626',          // red-600
  errorLight: '#fee2e2',     // red-100
  errorText: '#b91c1c',      // red-700
  errorContainer: '#fee2e2',
  info: '#2563eb',           // blue-600
  infoLight: '#dbeafe',      // blue-100
  infoText: '#1d4ed8',       // blue-700
  
  // Specific
  white: '#ffffff',
  black: '#000000',
  transparent: 'transparent',
  overlay: 'rgba(0, 0, 0, 0.5)',
  
  // Glow effects (for backward compatibility)
  glowPrimary: 'rgba(219, 39, 119, 0.2)',
  glowSecondary: 'rgba(236, 72, 153, 0.2)',
  
  // Badge colors
  syncBadgeBg: '#dcfce7',    // green-100
  syncBadgeText: '#15803d',  // green-700
  transcriptBadgeBg: '#dbeafe', // blue-100
  transcriptBadgeText: '#1d4ed8', // blue-700
  summaryBadgeBg: '#fce7f3', // pink-100
  summaryBadgeText: '#be185d', // pink-700
  
  // Speaker colors
  speakerBlue: '#3b82f6',
  speakerPink: '#ec4899',
  speakerGreen: '#22c55e',
  speakerOrange: '#f97316',
  speakerPurple: '#a855f7',
  
  // Tab bar
  tabBarBg: '#ffffff',
  tabBarBorder: '#e5e7eb',
  tabBarActive: '#db2777',
  tabBarInactive: '#9ca3af',
} as const;

export const darkColors = {
  // Primary
  primary: '#ec4899',        // pink-400 (brighter for dark)
  primaryDark: '#f43f5e',    // rose-400
  primaryLight: 'rgba(236, 72, 153, 0.2)', // pink with opacity
  primaryContainer: 'rgba(236, 72, 153, 0.1)',
  
  // Secondary (for backward compatibility)
  secondary: '#f472b6',      // pink-400
  secondaryContainer: 'rgba(236, 72, 153, 0.2)',
  onSecondary: '#ffffff',
  
  // Tertiary (for backward compatibility)
  tertiary: '#f9a8d4',
  tertiaryContainer: 'rgba(249, 168, 212, 0.2)',
  onTertiary: '#ffffff',
  
  // Background
  background: '#111827',     // gray-900
  backgroundGradientStart: '#111827',
  backgroundGradientEnd: '#1f2937',
  
  // Surface
  surface: '#1f2937',        // gray-800
  surfaceSecondary: '#1f2937',
  surfaceContainer: '#1f2937',
  surfaceContainerLow: '#111827',
  surfaceContainerHigh: '#374151',
  surfaceContainerHighest: '#4b5563',
  surfaceVariant: '#374151',
  surfaceGlass: 'rgba(31, 41, 55, 0.8)',
  
  // Text
  text: '#ffffff',
  textSecondary: '#9ca3af',  // gray-400
  textMuted: '#6b7280',      // gray-500
  textOnPrimary: '#ffffff',
  onSurface: '#ffffff',
  onSurfaceVariant: '#9ca3af',
  
  // Border
  border: '#374151',         // gray-700
  borderLight: '#1f2937',
  divider: '#374151',
  
  // Status
  success: '#22c55e',
  successLight: 'rgba(34, 197, 94, 0.2)',
  successText: '#4ade80',
  warning: '#eab308',
  warningLight: 'rgba(234, 179, 8, 0.2)',
  error: '#ef4444',
  errorLight: 'rgba(239, 68, 68, 0.2)',
  errorText: '#f87171',
  errorContainer: 'rgba(239, 68, 68, 0.2)',
  info: '#3b82f6',
  infoLight: 'rgba(59, 130, 246, 0.2)',
  infoText: '#60a5fa',
  
  // Specific
  white: '#ffffff',
  black: '#000000',
  transparent: 'transparent',
  overlay: 'rgba(0, 0, 0, 0.7)',
  
  // Glow effects (for backward compatibility)
  glowPrimary: 'rgba(236, 72, 153, 0.3)',
  glowSecondary: 'rgba(244, 63, 94, 0.3)',
  
  // Badge colors
  syncBadgeBg: 'rgba(34, 197, 94, 0.2)',
  syncBadgeText: '#4ade80',
  transcriptBadgeBg: 'rgba(59, 130, 246, 0.2)',
  transcriptBadgeText: '#60a5fa',
  summaryBadgeBg: 'rgba(236, 72, 153, 0.2)',
  summaryBadgeText: '#f472b6',
  
  // Speaker colors
  speakerBlue: '#3b82f6',
  speakerPink: '#ec4899',
  speakerGreen: '#22c55e',
  speakerOrange: '#f97316',
  speakerPurple: '#a855f7',
  
  // Tab bar
  tabBarBg: '#111827',
  tabBarBorder: '#374151',
  tabBarActive: '#ec4899',
  tabBarInactive: '#6b7280',
} as const;

export type ColorTheme = typeof lightColors | typeof darkColors;

// Keep spacing, borderRadius, fontSize, fontWeight as they are but update values:
export const spacing = { xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48 } as const;
export const borderRadius = { sm: 6, md: 8, lg: 12, xl: 16, xxl: 24, full: 9999 } as const;
export const fontSize = { xs: 10, sm: 12, md: 14, lg: 16, xl: 20, xxl: 24, heading: 24, display: 32 } as const;
export const fontWeight = { regular: '400' as const, medium: '500' as const, semibold: '600' as const, bold: '700' as const };

// Backward compatibility - keeping the old colors export as an alias to lightColors
export const colors = lightColors;
export type Colors = typeof colors;
export type Spacing = typeof spacing;
