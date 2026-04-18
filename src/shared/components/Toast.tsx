import React, { createContext, useContext, useState, useCallback, useRef } from 'react';
import { View, Text, StyleSheet, Platform } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSequence,
  withSpring,
  withTiming,
  runOnJS,
} from 'react-native-reanimated';
import { CheckCircle, AlertCircle, Info } from 'lucide-react-native';
import { useColors } from '../theme';
import { spacing, borderRadius, fontSize } from '../theme/tokens';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export type ToastType = 'success' | 'error' | 'info';

interface ToastContextValue {
  showToast: (message: string, type?: ToastType) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

export const useToast = () => {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return context;
};

export const ToastProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [message, setMessage] = useState('');
  const [type, setType] = useState<ToastType>('info');
  const colors = useColors();
  const insets = useSafeAreaInsets();
  
  const translateY = useSharedValue(-100);
  const opacity = useSharedValue(0);
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const hideToast = useCallback(() => {
    translateY.value = withTiming(-100, { duration: 300 });
    opacity.value = withTiming(0, { duration: 300 }, () => {
      runOnJS(setMessage)('');
    });
  }, [translateY, opacity]);

  const showToast = useCallback((newMessage: string, newType: ToastType = 'info') => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    setMessage(newMessage);
    setType(newType);

    translateY.value = withSpring(insets.top + spacing.md, {
      damping: 15,
      stiffness: 150,
    });
    opacity.value = withTiming(1, { duration: 200 });

    timeoutRef.current = setTimeout(() => {
      hideToast();
    }, 3000);
  }, [insets.top, translateY, opacity, hideToast]);

  const value = React.useMemo(() => ({ showToast }), [showToast]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }],
    opacity: opacity.value,
  }));

  const getIcon = () => {
    switch (type) {
      case 'success':
        return <CheckCircle size={20} color={colors.success} />;
      case 'error':
        return <AlertCircle size={20} color={colors.error} />;
      default:
        return <Info size={20} color={colors.info} />;
    }
  };

  const getBgColor = () => {
    return colors.surface;
  };

  return (
    <ToastContext.Provider value={value}>
      {children}
      {message ? (
        <Animated.View
          style={[
            styles.toastContainer,
            { backgroundColor: getBgColor(), borderColor: colors.border },
            animatedStyle,
          ]}
          pointerEvents="none"
        >
          {getIcon()}
          <Text style={[styles.message, { color: colors.text }]}>{message}</Text>
        </Animated.View>
      ) : null}
    </ToastContext.Provider>
  );
};

const styles = StyleSheet.create({
  toastContainer: {
    position: 'absolute',
    top: 0,
    left: spacing.lg,
    right: spacing.lg,
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 8,
    gap: spacing.sm,
    zIndex: 9999,
  },
  message: {
    fontSize: fontSize.md,
    fontWeight: '500',
    flex: 1,
  },
});
