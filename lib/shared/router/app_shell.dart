import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/widgets/app_button.dart';
import 'package:voicescribe_mobile/shared/widgets/app_card.dart';
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
              showAccent: true,
              accentColor: controller.modelState == ModelBootstrapState.failed
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
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

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.mic_none),
        selectedIcon: const Icon(Icons.mic),
        label: l10n.recording,
      ),
      NavigationDestination(
        icon: const Icon(Icons.description_outlined),
        selectedIcon: const Icon(Icons.description),
        label: l10n.transcript,
      ),
      NavigationDestination(
        icon: const Icon(Icons.auto_awesome_outlined),
        selectedIcon: const Icon(Icons.auto_awesome),
        label: l10n.summary,
      ),
      NavigationDestination(
        icon: const Icon(Icons.history_outlined),
        selectedIcon: const Icon(Icons.history),
        label: l10n.history,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: l10n.settings,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppLayout.mediumWidth) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  right: false,
                  child: NavigationRail(
                    extended: constraints.maxWidth >= AppLayout.expandedWidth,
                    selectedIndex: navigationShell.currentIndex,
                    groupAlignment: -0.86,
                    labelType: constraints.maxWidth >= AppLayout.expandedWidth
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.selected,
                    onDestinationSelected: _goBranch,
                    destinations: destinations
                        .map(
                          (destination) => NavigationRailDestination(
                            icon: destination.icon,
                            selectedIcon: destination.selectedIcon,
                            label: Text(destination.label),
                          ),
                        )
                        .toList(),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.95,
                    ),
                  ),
                  boxShadow: AppElevation.soft(theme.colorScheme.shadow),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  child: NavigationBar(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _goBranch,
                    destinations: destinations,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _goBranch(int value) {
    navigationShell.goBranch(
      value,
      initialLocation: value == navigationShell.currentIndex,
    );
  }
}
