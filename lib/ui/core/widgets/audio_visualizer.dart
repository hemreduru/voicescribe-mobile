import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:waveform_visualizer/waveform_visualizer.dart';

class AudioVisualizer extends StatefulWidget {
  const AudioVisualizer({required this.level, super.key});

  final double level;

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> {
  late final WaveformController _controller;
  double _displayLevel = 0;

  @override
  void initState() {
    super.initState();
    _controller = WaveformController(
      maxDataPoints: 80,
      updateInterval: const Duration(milliseconds: 32),
      smoothingFactor: 0.72,
    );
    _pushLevel(widget.level);
  }

  @override
  void didUpdateWidget(covariant AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _pushLevel(widget.level);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final glowOpacity = disableAnimations
        ? 0.16
        : (0.12 + (_displayLevel * 0.2)).clamp(0.12, 0.32);
    final orbSize = 38 + (_displayLevel * 20);

    return SizedBox(
      height: 116,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.78),
              scheme.tertiaryContainer.withValues(alpha: 0.54),
              scheme.surface.withValues(alpha: 0.96),
            ],
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.70),
          ),
          boxShadow: AppElevation.soft(scheme.primary),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.94,
                      colors: [
                        scheme.primary.withValues(alpha: glowOpacity),
                        scheme.tertiary.withValues(alpha: glowOpacity * 0.65),
                        Colors.transparent,
                      ],
                      stops: const [0.08, 0.54, 1],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: TickerMode(
                  enabled: !disableAnimations,
                  child: WaveformWidget(
                    controller: _controller,
                    height: 116,
                    style: WaveformStyle(
                      waveColor:
                          Color.lerp(scheme.primary, scheme.tertiary, 0.32) ??
                          scheme.primary,
                      backgroundColor: Colors.transparent,
                      barCount: 42,
                      barSpacing: 2.7,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.standardCurve,
                    width: orbSize,
                    height: orbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          scheme.primary.withValues(alpha: 0.90),
                          scheme.secondary.withValues(alpha: 0.72),
                          scheme.primary.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.58, 1],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.28),
                          blurRadius: 18 + (_displayLevel * 14),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      size: 18,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pushLevel(double rawLevel) {
    final normalized = _normalizeLevel(rawLevel);
    _displayLevel = normalized;
    _controller.updateAmplitude(normalized);
  }

  double _normalizeLevel(double rawLevel) {
    final clamped = rawLevel.clamp(0, 1).toDouble();
    if (clamped < 0.014) {
      return 0;
    }

    // Non-linear lift keeps quiet speech visible without clipping louder peaks.
    final lifted = math.pow(clamped, 0.58).toDouble();
    return (lifted * 1.16).clamp(0, 1).toDouble();
  }
}
