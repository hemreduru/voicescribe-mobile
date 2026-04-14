import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { StyleSheet, View } from 'react-native';
import { Mic, FileText, Sparkles, Clock, Users } from 'lucide-react-native';
import { RecordingStack } from './RecordingStack';
import { TranscriptStack } from './TranscriptStack';
import { SummaryStack } from './SummaryStack';
import { HistoryStack } from './HistoryStack';
import { SpeakerStack } from './SpeakerStack';
import { useColors } from '../theme';
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

  return (
    <View style={styles.container}>
      <Tab.Navigator
        screenOptions={({ route }) => ({
          headerShown: false,
          tabBarStyle: {
            backgroundColor: colors.tabBarBg,
            borderTopColor: colors.tabBarBorder,
            borderTopWidth: 1,
            height: 60,
            paddingBottom: 8,
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
          options={{ tabBarLabel: 'Kayıt' }}
        />
        <Tab.Screen
          name="TranscriptTab"
          component={TranscriptStack}
          options={{ tabBarLabel: 'Transkript' }}
        />
        <Tab.Screen
          name="SummaryTab"
          component={SummaryStack}
          options={{ tabBarLabel: 'Özet' }}
        />
        <Tab.Screen
          name="HistoryTab"
          component={HistoryStack}
          options={{ tabBarLabel: 'Geçmiş' }}
        />
        <Tab.Screen
          name="SpeakerTab"
          component={SpeakerStack}
          options={{ tabBarLabel: 'Konuşmacı' }}
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
    fontSize: 12,
    fontWeight: '500',
  },
});
