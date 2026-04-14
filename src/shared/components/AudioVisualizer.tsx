import React, { useEffect } from 'react';
import { View } from 'react-native';
import Animated, { useSharedValue, useAnimatedStyle, withRepeat, withTiming, withDelay } from 'react-native-reanimated';
import { useColors } from '../theme';

interface AudioVisualizerProps {
  isActive: boolean;
  barCount?: number;
}

const AnimatedBar: React.FC<{ index: number; isActive: boolean; color: string }> = ({ index, isActive, color }) => {
  const height = useSharedValue(8);

  useEffect(() => {
    if (isActive) {
      height.value = withDelay(
        index * 50,
        withRepeat(
          withTiming(Math.random() * 32 + 10, { duration: 400 + Math.random() * 200 }),
          -1,
          true
        )
      );
    } else {
      height.value = withTiming(8, { duration: 300 });
    }
  }, [isActive, index, height]);

  const animatedStyle = useAnimatedStyle(() => ({
    height: height.value,
  }));

  return (
    <Animated.View
      style={[
        {
          width: 3,
          borderRadius: 2,
          backgroundColor: color,
        },
        animatedStyle,
      ]}
    />
  );
};

export const AudioVisualizer: React.FC<AudioVisualizerProps> = ({ isActive, barCount = 20 }) => {
  const colors = useColors();

  return (
    <View style={{
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 3,
      height: 48,
    }}>
      {Array.from({ length: barCount }).map((_, i) => (
        <AnimatedBar key={i} index={i} isActive={isActive} color={colors.primary} />
      ))}
    </View>
  );
};
