import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { RecordingScreen } from '../../features/recording/presentation/screens/RecordingScreen';
import { SettingsScreen } from '../../features/settings/presentation/screens/SettingsScreen';
import type { RecordingStackParamList } from './types';

const Stack = createNativeStackNavigator<RecordingStackParamList>();

export const RecordingStack: React.FC = () => {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="Recording" component={RecordingScreen} />
      <Stack.Screen name="Settings" component={SettingsScreen} />
    </Stack.Navigator>
  );
};
