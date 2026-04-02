import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { SpeakerScreen } from '../../features/speaker/presentation/screens/SpeakerScreen';
import type { SpeakerStackParamList } from './types';
import { colors, fontSize } from '../theme';

const Stack = createNativeStackNavigator<SpeakerStackParamList>();

export const SpeakerStack: React.FC = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerStyle: { backgroundColor: colors.surface },
        headerTintColor: colors.text,
        headerTitleStyle: { fontSize: fontSize.lg, fontWeight: '600' },
        contentStyle: { backgroundColor: colors.background },
      }}>
      <Stack.Screen
        name="SpeakerList"
        component={SpeakerScreen}
        options={{ title: 'Speakers' }}
      />
    </Stack.Navigator>
  );
};
