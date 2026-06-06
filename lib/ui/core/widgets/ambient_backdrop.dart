import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:voicescribe_mobile/ui/core/theme/premium_tokens.dart';

/// A quiet, premium backdrop: a static base wash with two large blurred color
/// blobs that drift slowly behind the content.
///
/// Honors [MediaQueryData.disableAnimations]: when reduced motion is requested
/// the blobs are placed statically (no movement, no looping controller). Blob
/// alpha is kept low so foreground text contrast is never reduced below WCAG AA.
class AmbientBackdrop extends StatefulWidget {
  const AmbientBackdrop({required this.child, super.key});

  final Widget child;

  @override
  State<AmbientBackdrop> createState() => _AmbientBackdropState();
}

class _AmbientBackdropState extends State<AmbientBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradients = AppGradients.of(scheme);
    final accents = AppAccents.of(scheme);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Static base wash.
        DecoratedBox(decoration: BoxDecoration(gradient: gradients.ambient)),
        // Drifting blurred blobs.
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _BlobPainter(
                      progress: reduceMotion ? 0 : _controller.value,
                      glow: accents.glow,
                      brand: scheme.primary,
                      reduceMotion: reduceMotion,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({
    required this.progress,
    required this.glow,
    required this.brand,
    required this.reduceMotion,
  });

  final double progress;
  final Color glow;
  final Color brand;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final angle = progress * 2 * math.pi;
    // Two blobs drift on gentle, out-of-phase orbits.
    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.26 + 0.06 * math.cos(angle)),
        size.height * (0.22 + 0.05 * math.sin(angle)),
      ),
      radius: size.shortestSide * 0.55,
      color: glow.withValues(alpha: 0.10),
    );
    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.78 + 0.06 * math.cos(angle + math.pi)),
        size.height * (0.72 + 0.05 * math.sin(angle + math.pi)),
      ),
      radius: size.shortestSide * 0.5,
      color: brand.withValues(alpha: 0.08),
    );
  }

  void _drawBlob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 80),
    );
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glow != glow ||
        oldDelegate.brand != brand ||
        oldDelegate.reduceMotion != reduceMotion;
  }
}
