import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/utils/model_download_formatters.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_button.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_card.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_navigation.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_page.dart';
import 'package:voicescribe_mobile/ui/features/bootstrap/bloc/bootstrap_bloc.dart';

class BootstrapGate extends StatelessWidget {
  const BootstrapGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BootstrapBloc, BootstrapState>(
      builder: (context, state) {
        if (state.initialized) {
          return const SizedBox.shrink();
        }
        return BootstrapScreen(state: state);
      },
    );
  }
}

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({required this.state, super.key});

  final BootstrapState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progress = state.downloadProgress;
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
                    state.modelState == ModelBootstrapState.failed
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
                      formatModelDownloadProgress(l10n, progress),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  if (state.modelState == ModelBootstrapState.failed)
                    AppButton(
                      label: l10n.retrySetup,
                      icon: Icons.refresh,
                      onPressed: () => context.read<BootstrapBloc>().add(
                        const BootstrapRetried(),
                      ),
                    )
                  else
                    const CircularProgressIndicator(),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.errorMessage!,
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
}

class AppShell extends StatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currentIndex = widget.navigationShell.currentIndex;
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
                Expanded(child: widget.navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: widget.navigationShell,
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
