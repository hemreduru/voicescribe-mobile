import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { StyleSheet, View, TouchableOpacity, Platform } from 'react-native';
import { Mic, FileText, Sparkles, Clock, Users, Settings } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { RecordingStack } from './RecordingStack';
import { TranscriptStack } from './TranscriptStack';
import { SummaryStack } from './SummaryStack';
import { HistoryStack } from './HistoryStack';
import { SpeakerStack } from './SpeakerStack';
import { useColors } from '../theme';
import { useTranslation } from '../i18n';
import type { RootTabParamList } from './types';

const Tab = createBottomTabNavigator<RootTabParamList>();

type TabIconProps = {
  focused: boolean;
  size: number;
  color: string;
  iconName: keyof typeof tabIcons;
};

const tabIcons = {
  RecordingTab: Mic,
  TranscriptTab: FileText,
  SummaryTab: Sparkles,
  HistoryTab: Clock,
  SpeakerTab: Users,
};

const TabIcon: React.FC<TabIconProps> = ({ focused, size, color, iconName }) => {
  const Icon = tabIcons[iconName];
  return <Icon size={size} color={color} strokeWidth={focused ? 2.5 : 2} />;
};

export const AppNavigator: React.FC = () => {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const t = useTranslation();

  // Ensure bottom tab bar has enough padding for gesture navigation bar
  const bottomPadding = Math.max(insets.bottom, Platform.OS === 'android' ? 8 : 0);

  return (
    <View style={styles.container}>
      <Tab.Navigator
        screenOptions={({ route }) => ({
          headerShown: false,
          tabBarStyle: {
            backgroundColor: colors.tabBarBg,
            borderTopColor: colors.tabBarBorder,
            borderTopWidth: 1,
            height: 60 + bottomPadding,
            paddingBottom: bottomPadding,
            paddingTop: 8,
          },
          tabBarActiveTintColor: colors.tabBarActive,
          tabBarInactiveTintColor: colors.tabBarInactive,
          tabBarLabelStyle: styles.tabBarLabel,
          tabBarIcon: ({ focused, size, color }) => (
            <TabIcon focused={focused} size={size} color={color} iconName={route.name as keyof typeof tabIcons} />
          ),
        })}>
        <Tab.Screen
          name="RecordingTab"
          component={RecordingStack}
          options={{ tabBarLabel: t.tabRecording }}
        />
        <Tab.Screen
          name="TranscriptTab"
          component={TranscriptStack}
          options={{ tabBarLabel: t.tabTranscript }}
        />
        <Tab.Screen
          name="SummaryTab"
          component={SummaryStack}
          options={{ tabBarLabel: t.tabSummary }}
        />
        <Tab.Screen
          name="HistoryTab"
          component={HistoryStack}
          options={{ tabBarLabel: t.tabHistory }}
        />
        <Tab.Screen
          name="SpeakerTab"
          component={SpeakerStack}
          options={{ tabBarLabel: t.tabSpeaker }}
        />
      </Tab.Navigator>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  tabBarLabel: {
    fontSize: 11,
    fontWeight: '600',
  },
});
