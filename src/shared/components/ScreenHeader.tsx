import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Settings, Sun, Moon } from 'lucide-react-native';
import { useNavigation } from '@react-navigation/native';
import { useColors, useTheme } from '../theme';
import { spacing, fontSize } from '../theme/tokens';

interface ScreenHeaderProps {
  title: string;
  /** Optional right-side content to render alongside the settings button */
  rightContent?: React.ReactNode;
  /** Hide the settings button (e.g. on the Settings screen itself) */
  hideSettings?: boolean;
}

/**
 * Shared screen header with title, theme toggle, and settings button.
 * Visible on every screen for consistent navigation.
 */
export const ScreenHeader: React.FC<ScreenHeaderProps> = ({
  title,
  rightContent,
  hideSettings = false,
}) => {
  const colors = useColors();
  const { isDark, setMode, mode } = useTheme();
  const navigation = useNavigation<any>();

  const handleSettingsPress = () => {
    // Navigate to Settings screen through the RecordingTab stack
    // Use the root navigation to go to settings
    try {
      navigation.navigate('RecordingTab', { screen: 'Settings' });
    } catch {
      // Fallback: navigate directly if already in RecordingStack
      try {
        navigation.navigate('Settings');
      } catch {
        // no-op
      }
    }
  };

  const handleThemeToggle = () => {
    if (mode === 'light') {
      setMode('dark');
    } else if (mode === 'dark') {
      setMode('system');
    } else {
      setMode('light');
    }
  };

  return (
    <View style={styles.header}>
      <Text style={[styles.title, { color: colors.text }]}>{title}</Text>
      <View style={styles.actions}>
        {rightContent}
        <TouchableOpacity
          style={[styles.iconButton, { backgroundColor: colors.surfaceSecondary }]}
          onPress={handleThemeToggle}
          accessibilityLabel="Toggle theme"
        >
          {isDark ? (
            <Sun size={20} color={colors.primary} />
          ) : (
            <Moon size={20} color={colors.textSecondary} />
          )}
        </TouchableOpacity>
        {!hideSettings && (
          <TouchableOpacity
            style={[styles.iconButton, { backgroundColor: colors.surfaceSecondary }]}
            onPress={handleSettingsPress}
            accessibilityLabel="Settings"
          >
            <Settings size={20} color={colors.textSecondary} />
          </TouchableOpacity>
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: spacing.md,
    paddingBottom: spacing.md,
    paddingHorizontal: spacing.lg,
  },
  title: {
    fontSize: fontSize.heading,
    fontWeight: '700',
    flex: 1,
  },
  actions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  iconButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
});
