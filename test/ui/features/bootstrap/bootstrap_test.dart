import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
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

  test('loads onboarding status and applies transcription language', () async {
    final transcription = FakeTranscriptionService();
    final repo = FakeTranscriptRepository(
      initial: const TranscriptSnapshot(
        transcripts: [],
        chunks: [],
        summaries: [],
        preferences: AppPreferences(
          transcriptionLanguage: 'en',
        ),
      ),
    );
    final bloc = BootstrapBloc(
      transcriptRepository: repo,
      transcriptionService: transcription,
    );
    addTearDown(bloc.close);

    bloc.add(const BootstrapStarted());
    await bloc.stream.firstWhere((s) => s.isReady);

    expect(bloc.state.onboardingComplete, isFalse);
    expect(transcription.currentTranscriptionLanguage, 'en');

    bloc.add(const BootstrapOnboardingCompleted());
    await expectLater(
      bloc.stream,
      emitsThrough(predicate<BootstrapState>((s) => s.onboardingComplete)),
    );

    bloc.add(const BootstrapOnboardingReset());
    await expectLater(
      bloc.stream,
      emitsThrough(predicate<BootstrapState>((s) => !s.onboardingComplete)),
    );
  });
}
