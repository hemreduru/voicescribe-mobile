import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { SummaryScreen } from '../../features/summary/presentation/screens/SummaryScreen';
import type { SummaryStackParamList } from './types';
import { colors, fontSize } from '../theme';

const Stack = createNativeStackNavigator<SummaryStackParamList>();

export const SummaryStack: React.FC = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerStyle: { backgroundColor: colors.surface },
        headerTintColor: colors.text,
        headerTitleStyle: { fontSize: fontSize.lg, fontWeight: '600' },
        contentStyle: { backgroundColor: colors.background },
      }}>
      <Stack.Screen
        name="SummaryList"
        component={SummaryScreen}
        options={{ title: 'Summaries' }}
      />
    </Stack.Navigator>
  );
};
