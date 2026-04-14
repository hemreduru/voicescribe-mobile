import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { SpeakerScreen } from '../../features/speaker/presentation/screens/SpeakerScreen';
import type { SpeakerStackParamList } from './types';

const Stack = createNativeStackNavigator<SpeakerStackParamList>();

export const SpeakerStack: React.FC = () => {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="SpeakerList" component={SpeakerScreen} />
    </Stack.Navigator>
  );
};
