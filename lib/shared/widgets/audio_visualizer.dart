import 'package:flutter/material.dart';

class AudioVisualizer extends StatelessWidget {
  const AudioVisualizer({required this.level, super.key, this.barCount = 24});

  final double level;
  final int barCount;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (index) {
          final wave = ((index % 6) + 1) / 6;
          final height = 8 + (level.clamp(0, 1) * 44 * wave);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 5,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.35 + (wave * 0.45)),
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}
