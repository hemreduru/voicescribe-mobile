import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/theme/premium_tokens.dart';

/// Hero record control.
///
/// Idle: a calm breathing brand glow. Recording: concentric pulse rings in the
/// reserved recording-red plus a gradient core. Tapping gives a spring press
/// scale and a haptic. The icon crossfades between mic and stop.
///
/// Honors [MediaQueryData.disableAnimations]: when reduced motion is requested no
/// looping animation runs, but the idle/recording states stay clearly distinct
/// (core color, gradient and icon still differ).
class PulseRecordButton extends StatefulWidget {
  const PulseRecordButton({
    required this.isRecording,
    required this.onPressed,
    required this.dimension,
    required this.semanticLabel,
    super.key,
  });

  final bool isRecording;
  final double dimension;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  State<PulseRecordButton> createState() => _PulseRecordButtonState();
}

class _PulseRecordButtonState extends State<PulseRecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _syncLoop();
  }

  @override
  void didUpdateWidget(covariant PulseRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRecording != widget.isRecording) {
      _syncLoop();
    }
  }

  void _syncLoop({bool reduceMotion = false}) {
    if (reduceMotion) {
      if (_loop.isAnimating) _loop.stop();
      _loop.value = 0;
      return;
    }
    // Recording rings sweep faster than the idle breath.
    _loop.duration = widget.isRecording
        ? const Duration(milliseconds: 1800)
        : const Duration(milliseconds: 2600);
    _loop.repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isRecording) {
      AppHaptics.warning();
    } else {
      AppHaptics.medium();
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accents = AppAccents.of(scheme);
    final gradients = AppGradients.of(scheme);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // Keep the controller state in sync with the reduced-motion setting.
    if (reduceMotion && _loop.isAnimating) {
      _syncLoop(reduceMotion: true);
    } else if (!reduceMotion && !_loop.isAnimating) {
      _syncLoop();
    }

    final coreColor = widget.isRecording ? accents.recording : scheme.primary;
    final coreGradient = widget.isRecording
        ? gradients.recording
        : gradients.brand;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _handleTap,
        child: SizedBox.square(
          dimension: widget.dimension,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: reduceMotion ? Duration.zero : AppMotion.fast,
            curve: AppMotionX.expressive,
            child: AnimatedBuilder(
              animation: _loop,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PulsePainter(
                    progress: reduceMotion ? 0 : _loop.value,
                    isRecording: widget.isRecording,
                    color: widget.isRecording
                        ? accents.recording
                        : accents.glow,
                    reduceMotion: reduceMotion,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: _Core(
                  dimension: widget.dimension * 0.62,
                  gradient: coreGradient,
                  shadowColor: coreColor,
                  isRecording: widget.isRecording,
                  onColor: scheme.onPrimary,
                  reduceMotion: reduceMotion,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Core extends StatelessWidget {
  const _Core({
    required this.dimension,
    required this.gradient,
    required this.shadowColor,
    required this.isRecording,
    required this.onColor,
    required this.reduceMotion,
  });

  final double dimension;
  final Gradient gradient;
  final Color shadowColor;
  final bool isRecording;
  final Color onColor;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.42),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : AppMotion.normal,
        switchInCurve: AppMotionX.expressive,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          key: ValueKey(isRecording),
          color: onColor,
          size: dimension * 0.42,
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({
    required this.progress,
    required this.isRecording,
    required this.color,
    required this.reduceMotion,
  });

  final double progress;
  final bool isRecording;
  final Color color;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final coreRadius = size.width * 0.31;
    final maxRadius = size.width * 0.5;

    if (isRecording) {
      // Concentric rings expanding outward and fading.
      const ringCount = 3;
      for (var i = 0; i < ringCount; i++) {
        final t = reduceMotion
            ? (i + 1) / (ringCount + 1)
            : (progress + i / ringCount) % 1.0;
        final radius = coreRadius + (maxRadius - coreRadius) * t;
        final alpha = (1.0 - t) * (reduceMotion ? 0.16 : 0.28);
        if (alpha <= 0) continue;
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = color.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    } else {
      // Idle: a soft breathing glow halo around the core.
      final breath = reduceMotion
          ? 0.5
          : 0.5 + 0.5 * math.sin(progress * 2 * math.pi);
      final radius =
          coreRadius + (maxRadius - coreRadius) * (0.45 + 0.3 * breath);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: 0.10 + 0.06 * breath)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRecording != isRecording ||
        oldDelegate.color != color ||
        oldDelegate.reduceMotion != reduceMotion;
  }
}
