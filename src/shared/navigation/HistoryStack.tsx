import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { HistoryScreen } from '../../features/history/presentation/screens/HistoryScreen';
import type { HistoryStackParamList } from './types';
import { colors, fontSize } from '../theme';

const Stack = createNativeStackNavigator<HistoryStackParamList>();

export const HistoryStack: React.FC = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerStyle: { backgroundColor: colors.surface },
        headerTintColor: colors.text,
        headerTitleStyle: { fontSize: fontSize.lg, fontWeight: '600' },
        contentStyle: { backgroundColor: colors.background },
      }}>
      <Stack.Screen
        name="HistoryList"
        component={HistoryScreen}
        options={{ title: 'History' }}
      />
    </Stack.Navigator>
  );
};
