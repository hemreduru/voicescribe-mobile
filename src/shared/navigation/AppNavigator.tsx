import React, { useEffect } from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { StyleSheet, View } from 'react-native';
import Animated, { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated';
import { RecordingStack } from './RecordingStack';
import { TranscriptStack } from './TranscriptStack';
import { SummaryStack } from './SummaryStack';
import { HistoryStack } from './HistoryStack';
import { SpeakerStack } from './SpeakerStack';
import { colors, fontSize, borderRadius } from '../theme';
import type { RootTabParamList } from './types';

const Tab = createBottomTabNavigator<RootTabParamList>();

const tabIcons: Record<keyof RootTabParamList, string> = {
  RecordingTab: '🎙️',
  TranscriptTab: '📝',
  SummaryTab: '✨',
  HistoryTab: '📂',
  SpeakerTab: '👤',
};

// Animated icon component
const TabIcon = ({ focused, name }: { focused: boolean; name: string }) => {
  const scale = useSharedValue(focused ? 1.2 : 1);

  useEffect(() => {
    scale.value = withSpring(focused ? 1.2 : 1, {
      mass: 0.5,
      damping: 12,
      stiffness: 150,
    });
  }, [focused, scale]);

  const animatedStyle = useAnimatedStyle(() => {
    return {
      transform: [{ scale: scale.value }],
    };
  });

  return (
    <View style={[styles.iconContainer, focused && styles.iconContainerActive]}>
      <Animated.Text style={[styles.tabIcon, focused && styles.tabIconActive, animatedStyle]}>
        {name}
      </Animated.Text>
    </View>
  );
};

export const AppNavigator: React.FC = () => {
  return (
    <View style={styles.container}>
      <Tab.Navigator
        screenOptions={({ route }) => ({
          headerShown: false,
          tabBarStyle: styles.tabBar,
          tabBarActiveTintColor: colors.primary,
          tabBarInactiveTintColor: colors.textMuted,
          tabBarLabelStyle: styles.tabBarLabel,
          tabBarIcon: ({ focused }) => (
            <TabIcon focused={focused} name={tabIcons[route.name]} />
          ),
          tabBarBackground: () => <View style={styles.tabBackground} />,
        })}>
        <Tab.Screen name="RecordingTab" component={RecordingStack} options={{ tabBarLabel: 'Record' }} />
        <Tab.Screen name="TranscriptTab" component={TranscriptStack} options={{ tabBarLabel: 'Logs' }} />
        <Tab.Screen name="SummaryTab" component={SummaryStack} options={{ tabBarLabel: 'Notes' }} />
        <Tab.Screen name="HistoryTab" component={HistoryStack} options={{ tabBarLabel: 'Vault' }} />
        <Tab.Screen name="SpeakerTab" component={SpeakerStack} options={{ tabBarLabel: 'Voices' }} />
      </Tab.Navigator>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background, // Deep background
  },
  tabBar: {
    position: 'absolute',
    bottom: 24,
    left: 20,
    right: 20,
    elevation: 0,
    backgroundColor: 'transparent',
    borderTopWidth: 0,
    height: 64,
  },
  tabBackground: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: colors.surfaceGlass,
    borderRadius: borderRadius.xl,
    borderWidth: 1,
    borderColor: colors.border,
  },
  tabBarLabel: {
    fontSize: fontSize.xs,
    fontFamily: 'sans-serif-medium',
    paddingBottom: 4,
  },
  iconContainer: {
    paddingTop: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconContainerActive: {
    shadowColor: colors.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
  },
  tabIcon: {
    fontSize: 20,
    opacity: 0.6,
  },
  tabIconActive: {
    opacity: 1,
  },
});

