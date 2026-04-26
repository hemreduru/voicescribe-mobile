import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';

class BootstrapGate extends ConsumerWidget {
  const BootstrapGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    if (controller.modelState == ModelBootstrapState.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (GoRouterState.of(context).uri.path == '/') {
          context.go('/recording');
        }
      });
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.graphic_eq,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.bootstrapTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                        const SizedBox(height: 20),
                        LinearProgressIndicator(
                          value: percent == null ? null : percent / 100,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          percent == null
                              ? _formatBytes(progress.bytesDownloaded)
                              : '${l10n.downloadingModel} ${percent.floor()}%',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (controller.modelState == ModelBootstrapState.failed)
                        FilledButton.icon(
                          onPressed: controller.bootstrap,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.retrySetup),
                        )
                      else
                        const CircularProgressIndicator(),
                      if (controller.bootstrapError != null) ...[
                        const SizedBox(height: 16),
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
            );
          },
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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (value) => navigationShell.goBranch(
              value,
              initialLocation: value == navigationShell.currentIndex,
            ),
            destinations: [
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
                icon: const Icon(Icons.group_outlined),
                selectedIcon: const Icon(Icons.group),
                label: l10n.speaker,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
