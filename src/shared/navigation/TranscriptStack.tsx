import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { TranscriptScreen } from '../../features/transcript/presentation/screens/TranscriptScreen';
import type { TranscriptStackParamList } from './types';
import { colors, fontSize } from '../theme';

const Stack = createNativeStackNavigator<TranscriptStackParamList>();

export const TranscriptStack: React.FC = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerStyle: { backgroundColor: colors.surface },
        headerTintColor: colors.text,
        headerTitleStyle: { fontSize: fontSize.lg, fontWeight: '600' },
        contentStyle: { backgroundColor: colors.background },
      }}>
      <Stack.Screen
        name="TranscriptList"
        component={TranscriptScreen}
        options={{ title: 'Transcripts' }}
      />
    </Stack.Navigator>
  );
};
