import React from 'react';
import { View, TextInput, StyleProp, ViewStyle } from 'react-native';
import { Search } from 'lucide-react-native';
import { useColors } from '../theme';
import { spacing, fontSize, borderRadius } from '../theme/tokens';

interface SearchBarProps {
  value: string;
  onChangeText: (text: string) => void;
  placeholder?: string;
  style?: StyleProp<ViewStyle>;
}

export const SearchBar: React.FC<SearchBarProps> = ({ value, onChangeText, placeholder = 'Ara...', style }) => {
  const colors = useColors();

  return (
    <View style={[{
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: colors.surface,
      borderWidth: 1,
      borderColor: colors.border,
      borderRadius: borderRadius.lg,
      paddingHorizontal: spacing.md,
      height: 44,
    }, style]}>
      <Search size={20} color={colors.textMuted} />
      <TextInput
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={colors.textMuted}
        style={{
          flex: 1,
          marginLeft: spacing.sm,
          fontSize: fontSize.md,
          color: colors.text,
          padding: 0,
        }}
      />
    </View>
  );
};
