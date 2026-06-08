import 'package:flutter/material.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';

/// Shimmering placeholder primitives shown while content loads, so the user sees
/// structured progress instead of a bare spinner (Material "skeleton screen").
/// Built entirely from design-system tokens — no external package.

/// A single rounded placeholder bar sized as a fraction of the available width.
class AppSkeletonBar extends StatelessWidget {
  const AppSkeletonBar({required this.widthFactor, this.height = 12, super.key});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.08);
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    );
  }
}

/// A card-shaped placeholder: a title bar plus [lineCount] body bars.
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({this.lineCount = 2, super.key});

  final int lineCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeletonBar(widthFactor: 0.6, height: 16),
          for (var i = 0; i < lineCount; i++) ...[
            const SizedBox(height: AppSpacing.sm),
            AppSkeletonBar(widthFactor: i.isEven ? 0.9 : 0.75),
          ],
        ],
      ),
    );
  }
}

/// Wraps [child] in a gentle, looping fade so it reads as a loading placeholder.
/// Respects reduced-motion by holding a static dimmed state.
class AppSkeletonShimmer extends StatefulWidget {
  const AppSkeletonShimmer({required this.child, super.key});

  final Widget child;

  @override
  State<AppSkeletonShimmer> createState() => _AppSkeletonShimmerState();
}

class _AppSkeletonShimmerState extends State<AppSkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 0.7;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 0.9).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// A non-scrolling column of shimmering [AppSkeletonCard]s for list/detail
/// loading states.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    this.itemCount = 6,
    this.lineCount = 2,
    this.physics = const NeverScrollableScrollPhysics(),
    super.key,
  });

  final int itemCount;
  final int lineCount;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonShimmer(
      child: ListView.separated(
        physics: physics,
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm + 2),
        itemBuilder: (context, index) => AppSkeletonCard(lineCount: lineCount),
      ),
    );
  }
}
