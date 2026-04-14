import React from 'react';
import { TouchableOpacity, View, Text } from 'react-native';
import { ChevronRight } from 'lucide-react-native';
import { useColors } from '../theme';
import { spacing, fontSize } from '../theme/tokens';

interface SettingsRowProps {
  icon: React.ReactNode;
  title: string;
  subtitle?: string;
  onPress?: () => void;
  rightElement?: React.ReactNode;
  showChevron?: boolean;
  danger?: boolean;
}

export const SettingsRow: React.FC<SettingsRowProps> = ({
  icon, title, subtitle, onPress, rightElement, showChevron = false, danger = false,
}) => {
  const colors = useColors();
  const Wrapper = onPress ? TouchableOpacity : View;

  return (
    <Wrapper
      onPress={onPress}
      activeOpacity={0.7}
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: spacing.md,
      }}
    >
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: spacing.md, flex: 1 }}>
        <View style={{ width: 20, height: 20, alignItems: 'center', justifyContent: 'center' }}>
          {icon}
        </View>
        <View style={{ flex: 1 }}>
          <Text style={{
            fontSize: fontSize.md,
            fontWeight: '500',
            color: danger ? colors.error : colors.text,
          }}>
            {title}
          </Text>
          {subtitle && (
            <Text style={{ fontSize: fontSize.sm, color: colors.textSecondary, marginTop: 2 }}>
              {subtitle}
            </Text>
          )}
        </View>
      </View>
      {rightElement}
      {showChevron && <ChevronRight size={20} color={colors.textMuted} />}
    </Wrapper>
  );
};
