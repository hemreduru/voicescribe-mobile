import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Text, StyleSheet } from 'react-native';
import { RecordingStack } from './RecordingStack';
import { TranscriptStack } from './TranscriptStack';
import { SummaryStack } from './SummaryStack';
import { HistoryStack } from './HistoryStack';
import { SpeakerStack } from './SpeakerStack';
import { colors, fontSize } from '../theme';
import type { RootTabParamList } from './types';

const Tab = createBottomTabNavigator<RootTabParamList>();

const tabIcons: Record<keyof RootTabParamList, string> = {
  RecordingTab: '🎙️',
  TranscriptTab: '📝',
  SummaryTab: '✨',
  HistoryTab: '📂',
  SpeakerTab: '👤',
};

export const AppNavigator: React.FC = () => {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        headerShown: false,
        tabBarStyle: styles.tabBar,
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.textMuted,
        tabBarLabelStyle: styles.tabBarLabel,
        tabBarIcon: ({ focused }) => (
          <Text style={[styles.tabIcon, focused && styles.tabIconActive]}>
            {tabIcons[route.name]}
          </Text>
        ),
      })}>
      <Tab.Screen
        name="RecordingTab"
        component={RecordingStack}
        options={{ tabBarLabel: 'Record' }}
      />
      <Tab.Screen
        name="TranscriptTab"
        component={TranscriptStack}
        options={{ tabBarLabel: 'Transcript' }}
      />
      <Tab.Screen
        name="SummaryTab"
        component={SummaryStack}
        options={{ tabBarLabel: 'Summary' }}
      />
      <Tab.Screen
        name="HistoryTab"
        component={HistoryStack}
        options={{ tabBarLabel: 'History' }}
      />
      <Tab.Screen
        name="SpeakerTab"
        component={SpeakerStack}
        options={{ tabBarLabel: 'Speakers' }}
      />
    </Tab.Navigator>
  );
};

const styles = StyleSheet.create({
  tabBar: {
    backgroundColor: colors.surface,
    borderTopColor: colors.border,
    borderTopWidth: 1,
    paddingTop: 4,
    height: 60,
  },
  tabBarLabel: {
    fontSize: fontSize.xs,
    fontWeight: '500',
    marginBottom: 4,
  },
  tabIcon: {
    fontSize: 20,
    opacity: 0.5,
  },
  tabIconActive: {
    opacity: 1,
  },
});
