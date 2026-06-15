import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/ui/features/onboarding/bloc/onboarding_cubit.dart';

import '../../../helpers/fakes.dart';

void main() {
  late FakeTranscriptRepository repo;
  late FakeTranscriptionService transcription;

  OnboardingCubit build({
    bool supported = true,
    String deviceLanguageCode = 'en',
  }) {
    return OnboardingCubit(
      transcriptRepository: repo,
      localLlmModelService: FakeLocalLlmModelService(supported: supported),
      transcriptionService: transcription,
      deviceLanguageCode: deviceLanguageCode,
    );
  }

  setUp(() {
    repo = FakeTranscriptRepository();
    transcription = FakeTranscriptionService();
  });

  tearDown(() => repo.dispose());

  test('init seeds language from device locale and recommends on-device', () async {
    final cubit = build(deviceLanguageCode: 'tr');
    await cubit.init();
    expect(cubit.state.draft.transcriptionLanguage, 'tr');
    expect(cubit.state.deviceSupportsLocal, isTrue);
    expect(cubit.state.draft.summaryProvider, 'local');
    await cubit.close();
  });

  test('init recommends cloud when the device cannot run on-device AI', () async {
    final cubit = build(supported: false);
    await cubit.init();
    expect(cubit.state.deviceSupportsLocal, isFalse);
    expect(cubit.state.draft.summaryProvider, 'cloud');
    await cubit.close();
  });

  test('cannot pick on-device when unsupported', () async {
    final cubit = build(supported: false);
    await cubit.init();
    cubit.setSummaryProvider('local');
    expect(cubit.state.draft.summaryProvider, 'cloud');
    await cubit.close();
  });

  test('finish persists hasSeenOnboarding and applies the language', () async {
    final cubit = build();
    await cubit.init();
    cubit.setTranscriptionLanguage('tr');
    cubit.setThemeMode('dark');
    await cubit.finish();

    final saved = repo.savedPreferences['latest'];
    expect(saved, isNotNull);
    expect(saved!.hasSeenOnboarding, isTrue);
    expect(saved.transcriptionLanguage, 'tr');
    expect(saved.themeMode, 'dark');
    expect(transcription.language, 'tr');
    expect(cubit.state.completed, isTrue);
    await cubit.close();
  });

  test('navigation clamps to valid pages', () async {
    final cubit = build();
    await cubit.init();
    cubit.back();
    expect(cubit.state.pageIndex, 0);
    for (var i = 0; i < OnboardingCubit.pageCount + 2; i++) {
      cubit.next();
    }
    expect(cubit.state.pageIndex, OnboardingCubit.pageCount - 1);
    await cubit.close();
  });
}
