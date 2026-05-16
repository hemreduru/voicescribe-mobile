import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/widgets/app_button.dart';
import 'package:voicescribe_mobile/shared/widgets/app_card.dart';
import 'package:voicescribe_mobile/shared/widgets/app_navigation.dart';
import 'package:voicescribe_mobile/shared/widgets/app_page.dart';

class BootstrapGate extends ConsumerWidget {
  const BootstrapGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    if (controller.isAuthResolved) {
      return const SizedBox.shrink();
    }
    return BootstrapScreen(controller: controller);
  }
}

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progress = controller.downloadProgress;
    final percent = progress?.percent;

    return Scaffold(
      body: SafeArea(
        child: AppConstrainedBody(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.bootstrapTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    controller.modelState == ModelBootstrapState.failed
                        ? l10n.bootstrapFailed
                        : l10n.bootstrapMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    LinearProgressIndicator(
                      value: percent == null ? null : percent / 100,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      percent == null
                          ? _formatBytes(progress.bytesDownloaded)
                          : '${l10n.downloadingModel} ${percent.floor()}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  if (controller.modelState == ModelBootstrapState.failed)
                    AppButton(
                      label: l10n.retrySetup,
                      icon: Icons.refresh,
                      onPressed: controller.bootstrap,
                    )
                  else
                    const CircularProgressIndicator(),
                  if (controller.bootstrapError != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      controller.bootstrapError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb < 1) {
      return '${(bytes / 1024).round()} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class AppShell extends StatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _lastIndex = 0;
  int _direction = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currentIndex = widget.navigationShell.currentIndex;
    if (currentIndex != _lastIndex) {
      _direction = currentIndex > _lastIndex ? 1 : -1;
      _lastIndex = currentIndex;
    }
    final destinations = [
      AppNavigationDestination(
        icon: Icons.mic_none,
        selectedIcon: Icons.mic,
        label: l10n.recording,
      ),
      AppNavigationDestination(
        icon: Icons.description_outlined,
        selectedIcon: Icons.description,
        label: l10n.transcript,
      ),
      AppNavigationDestination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.settings,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppLayout.mediumWidth) {
          return Scaffold(
            body: Row(
              children: [
                AppSideNavigationRail(
                  extended: constraints.maxWidth >= AppLayout.expandedWidth,
                  selectedIndex: currentIndex,
                  onDestinationSelected: _goBranch,
                  destinations: destinations,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _BranchTransition(
                    index: currentIndex,
                    direction: _direction,
                    child: widget.navigationShell,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: _BranchTransition(
            index: currentIndex,
            direction: _direction,
            child: widget.navigationShell,
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: AppBottomNavigation(
                selectedIndex: currentIndex,
                onDestinationSelected: _goBranch,
                destinations: destinations,
              ),
            ),
          ),
        );
      },
    );
  }

  void _goBranch(int value) {
    widget.navigationShell.goBranch(
      value,
      initialLocation: value == widget.navigationShell.currentIndex,
    );
  }
}

class _BranchTransition extends StatelessWidget {
  const _BranchTransition({
    required this.index,
    required this.direction,
    required this.child,
  });

  final int index;
  final int direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(index),
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.normal,
      curve: AppMotion.standardCurve,
      child: RepaintBoundary(child: child),
      builder: (context, value, child) {
        return FractionalTranslation(
          translation: Offset(direction * (1 - value) * 0.025, 0),
          child: child,
        );
      },
    );
  }
}
