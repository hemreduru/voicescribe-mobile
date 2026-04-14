import React from 'react';
import { View, Text } from 'react-native';
import { useColors } from '../theme';
import { spacing, fontSize, borderRadius } from '../theme/tokens';

interface SectionCardProps {
  title?: string;
  children: React.ReactNode;
}

export const SectionCard: React.FC<SectionCardProps> = ({ title, children }) => {
  const colors = useColors();

  return (
    <View style={{ marginBottom: spacing.lg }}>
      {title && (
        <Text style={{
          fontSize: fontSize.lg,
          fontWeight: '600',
          color: colors.text,
          marginBottom: spacing.md,
        }}>
          {title}
        </Text>
      )}
      <View style={{
        backgroundColor: colors.surface,
        borderRadius: borderRadius.lg,
        borderWidth: 1,
        borderColor: colors.border,
        overflow: 'hidden',
      }}>
        {React.Children.map(children, (child, index) => (
          <>
            {index > 0 && (
              <View style={{ height: 1, backgroundColor: colors.border, marginHorizontal: spacing.md }} />
            )}
            {child}
          </>
        ))}
      </View>
    </View>
  );
};
