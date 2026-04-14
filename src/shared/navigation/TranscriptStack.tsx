import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { TranscriptScreen } from '../../features/transcript/presentation/screens/TranscriptScreen';
import type { TranscriptStackParamList } from './types';

const Stack = createNativeStackNavigator<TranscriptStackParamList>();

export const TranscriptStack: React.FC = () => {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="TranscriptList" component={TranscriptScreen} />
    </Stack.Navigator>
  );
};
