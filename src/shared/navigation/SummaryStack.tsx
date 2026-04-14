import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { SummaryScreen } from '../../features/summary/presentation/screens/SummaryScreen';
import type { SummaryStackParamList } from './types';

const Stack = createNativeStackNavigator<SummaryStackParamList>();

export const SummaryStack: React.FC = () => {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="SummaryList" component={SummaryScreen} />
    </Stack.Navigator>
  );
};
