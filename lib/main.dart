import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/history/history_screen.dart';
import 'features/recording/recording_screen.dart';
import 'features/speaker/speaker_screen.dart';
import 'features/summary/summary_screen.dart';
import 'features/transcript/transcript_screen.dart';
import 'shared/i18n/app_strings.dart';
import 'shared/state/app_controller.dart';
import 'shared/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: VoiceScribeApp()));
}

class VoiceScribeApp extends StatelessWidget {
  const VoiceScribeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: const AppStrings().appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const BootstrapGate(),
    );
  }
}

class BootstrapGate extends ConsumerWidget {
  const BootstrapGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    if (controller.modelState == ModelBootstrapState.ready) {
      return const AppShell();
    }
    return BootstrapScreen(controller: controller);
  }
}

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    const strings = AppStrings();
    final theme = Theme.of(context);
    final progress = controller.downloadProgress;
    final percent = progress?.percent;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                  strings.bootstrapTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  controller.modelState == ModelBootstrapState.failed
                      ? strings.bootstrapFailed
                      : strings.bootstrapMessage,
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
                        : '${strings.downloadingModel} ${percent.floor()}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                if (controller.modelState == ModelBootstrapState.failed)
                  FilledButton.icon(
                    onPressed: controller.bootstrap,
                    icon: const Icon(Icons.refresh),
                    label: Text(strings.retrySetup),
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
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  static const _strings = AppStrings();

  final _screens = const [
    RecordingScreen(),
    TranscriptScreen(),
    SummaryScreen(),
    HistoryScreen(),
    SpeakerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.mic_none),
                selectedIcon: const Icon(Icons.mic),
                label: _strings.recording,
              ),
              NavigationDestination(
                icon: const Icon(Icons.description_outlined),
                selectedIcon: const Icon(Icons.description),
                label: _strings.transcript,
              ),
              NavigationDestination(
                icon: const Icon(Icons.auto_awesome_outlined),
                selectedIcon: const Icon(Icons.auto_awesome),
                label: _strings.summary,
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history),
                label: _strings.history,
              ),
              NavigationDestination(
                icon: const Icon(Icons.group_outlined),
                selectedIcon: const Icon(Icons.group),
                label: _strings.speaker,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
