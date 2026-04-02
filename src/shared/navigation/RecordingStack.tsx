import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { RecordingScreen } from '../../features/recording/presentation/screens/RecordingScreen';
import type { RecordingStackParamList } from './types';
import { colors, fontSize } from '../theme';

const Stack = createNativeStackNavigator<RecordingStackParamList>();

export const RecordingStack: React.FC = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerStyle: { backgroundColor: colors.surface },
        headerTintColor: colors.text,
        headerTitleStyle: { fontSize: fontSize.lg, fontWeight: '600' },
        contentStyle: { backgroundColor: colors.background },
      }}>
      <Stack.Screen
        name="Recording"
        component={RecordingScreen}
        options={{ title: 'Record' }}
      />
    </Stack.Navigator>
  );
};
