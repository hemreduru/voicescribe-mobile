import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/ui/features/bootstrap/bloc/bootstrap_bloc.dart';

import '../../../helpers/fakes.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (methodCall) async => Directory.systemTemp.path,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });

  BootstrapBloc build(FakeTranscriptRepository repo, {required bool supported}) {
    return BootstrapBloc(
      transcriptRepository: repo,
      transcriptionService: FakeTranscriptionService(),
      localLlmModelService: FakeLocalLlmModelService(supported: supported),
    );
  }

  test('an unsupported device falls back local->cloud at bootstrap', () async {
    final repo = FakeTranscriptRepository();
    final bloc = build(repo, supported: false);
    addTearDown(bloc.close);

    bloc.add(const BootstrapStarted());
    await bloc.stream.firstWhere((s) => s.isReady);

    expect(repo.savedPreferences['latest']?.summaryProvider, 'cloud');
  });

  test('a capable device keeps the on-device default', () async {
    final repo = FakeTranscriptRepository();
    final bloc = build(repo, supported: true);
    addTearDown(bloc.close);

    bloc.add(const BootstrapStarted());
    await bloc.stream.firstWhere((s) => s.isReady);

    // No preference correction was needed, so nothing was persisted.
    expect(repo.savedPreferences['latest'], isNull);
    expect(bloc.state.onboardingComplete, isFalse);
  });
}
