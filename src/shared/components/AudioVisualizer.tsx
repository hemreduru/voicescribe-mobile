import React, { useEffect } from 'react';
import { View, StyleSheet } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSpring,
  interpolate,
  Easing,
} from 'react-native-reanimated';
import { useColors } from '../theme';

interface AudioVisualizerProps {
  /** Whether the visualizer is active (recording in progress) */
  isActive: boolean;
  /** Number of bars to display */
  barCount?: number;
  /** Current audio level from mic (0-1 normalized) */
  audioLevel?: number;
}

/**
 * Generates a deterministic pseudo-random value for a given bar index + seed.
 * This provides organic variation without true randomness.
 */
function pseudoRandom(index: number, seed: number): number {
  const x = Math.sin(index * 12.9898 + seed * 78.233) * 43758.5453;
  return x - Math.floor(x);
}

/**
 * Individual animated bar that reacts to audio level.
 * Each bar has slight offset/variation to create organic wave effect.
 */
const AnimatedBar: React.FC<{
  index: number;
  barCount: number;
  isActive: boolean;
  audioLevel: number;
  color: string;
  accentColor: string;
}> = ({ index, barCount, isActive, audioLevel, color, accentColor }) => {
  const barHeight = useSharedValue(4);
  const barOpacity = useSharedValue(0.3);

  useEffect(() => {
    if (!isActive) {
      barHeight.value = withTiming(4, { duration: 400, easing: Easing.out(Easing.ease) });
      barOpacity.value = withTiming(0.3, { duration: 400 });
      return;
    }

    // Each bar gets a unique variation factor based on its position
    const centerDistance = Math.abs(index - barCount / 2) / (barCount / 2);
    const positionFactor = 1 - centerDistance * 0.5; // Center bars are taller
    const variation = pseudoRandom(index, Math.floor(audioLevel * 10)) * 0.4 + 0.6;

    // Map audioLevel (0-1) to bar height with organic variation
    const minHeight = 4;
    const maxHeight = 44;
    const targetHeight = minHeight + (maxHeight - minHeight) * audioLevel * positionFactor * variation;

    // Use spring for natural bounce feel at high levels, timing for smooth at low
    if (audioLevel > 0.3) {
      barHeight.value = withSpring(targetHeight, {
        damping: 12,
        stiffness: 180,
        mass: 0.5,
      });
    } else {
      barHeight.value = withTiming(targetHeight, {
        duration: 120,
        easing: Easing.out(Easing.quad),
      });
    }

    // Opacity based on level — bars glow brighter at higher levels
    const targetOpacity = interpolate(audioLevel, [0, 0.3, 0.7, 1], [0.3, 0.5, 0.8, 1.0]);
    barOpacity.value = withTiming(targetOpacity * (0.6 + positionFactor * 0.4), { duration: 100 });
  }, [isActive, audioLevel, index, barCount, barHeight, barOpacity]);

  const animatedStyle = useAnimatedStyle(() => ({
    height: barHeight.value,
    opacity: barOpacity.value,
  }));

  // Use accent color for center bars, primary for outer bars
  const centerDistance = Math.abs(index - barCount / 2) / (barCount / 2);
  const barColor = centerDistance < 0.3 ? accentColor : color;

  return (
    <Animated.View
      style={[
        styles.bar,
        { backgroundColor: barColor },
        animatedStyle,
      ]}
    />
  );
};

export const AudioVisualizer: React.FC<AudioVisualizerProps> = ({
  isActive,
  barCount = 24,
  audioLevel = 0,
}) => {
  const colors = useColors();

  return (
    <View style={styles.container}>
      {Array.from({ length: barCount }).map((_, i) => (
        <AnimatedBar
          key={i}
          index={i}
          barCount={barCount}
          isActive={isActive}
          audioLevel={audioLevel}
          color={colors.primary}
          accentColor={colors.secondary}
        />
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2.5,
    height: 52,
  },
  bar: {
    width: 3,
    borderRadius: 1.5,
    minHeight: 4,
  },
});
