import 'package:bloc/bloc.dart';
import 'package:voicescribe_mobile/data/services/llm/llm_model_service.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';

class OnboardingState {
  const OnboardingState({
    this.pageIndex = 0,
    this.draft = const AppPreferences(),
    this.deviceSupportsLocal = true,
    this.saving = false,
    this.completed = false,
  });

  final int pageIndex;
  final AppPreferences draft;

  /// Whether this device can run the on-device engine (drives the recommended
  /// AI-location default and disables the on-device option when it can't).
  final bool deviceSupportsLocal;
  final bool saving;
  final bool completed;

  OnboardingState copyWith({
    int? pageIndex,
    AppPreferences? draft,
    bool? deviceSupportsLocal,
    bool? saving,
    bool? completed,
  }) {
    return OnboardingState(
      pageIndex: pageIndex ?? this.pageIndex,
      draft: draft ?? this.draft,
      deviceSupportsLocal: deviceSupportsLocal ?? this.deviceSupportsLocal,
      saving: saving ?? this.saving,
      completed: completed ?? this.completed,
    );
  }
}

/// Drives the first-run wizard: holds the in-progress preference draft, seeds
/// smart defaults from the device (locale + performance tier), and persists the
/// result with `hasSeenOnboarding = true` on finish.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required TranscriptRepository transcriptRepository,
    required LocalLlmModelService localLlmModelService,
    required TranscriptionService transcriptionService,
    required String deviceLanguageCode,
  }) : _transcriptRepository = transcriptRepository,
       _localLlmModelService = localLlmModelService,
       _transcriptionService = transcriptionService,
       _deviceLanguageCode = deviceLanguageCode,
       super(const OnboardingState());

  final TranscriptRepository _transcriptRepository;
  final LocalLlmModelService _localLlmModelService;
  final TranscriptionService _transcriptionService;
  final String _deviceLanguageCode;

  static const int pageCount = 5;

  Future<void> init() async {
    final initialLanguage = switch (_deviceLanguageCode) {
      'tr' => 'tr',
      'en' => 'en',
      _ => 'auto',
    };
    bool supported;
    try {
      supported = await _localLlmModelService.isSupported();
    } catch (_) {
      supported = false;
    }
    emit(
      state.copyWith(
        deviceSupportsLocal: supported,
        draft: state.draft.copyWith(
          transcriptionLanguage:
              AppPreferences.normalizeTranscriptionLanguage(initialLanguage),
          // Recommend on-device when the phone can run it, else cloud.
          summaryProvider: supported ? 'local' : 'cloud',
        ),
      ),
    );
  }

  void goTo(int index) {
    emit(state.copyWith(pageIndex: index.clamp(0, pageCount - 1)));
  }

  void next() => goTo(state.pageIndex + 1);

  void back() => goTo(state.pageIndex - 1);

  void setAppLanguage(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          localePreference: AppPreferences.normalizeLocalePreference(value),
        ),
      ),
    );
  }

  void setTranscriptionLanguage(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          transcriptionLanguage: AppPreferences.normalizeTranscriptionLanguage(
            value,
          ),
        ),
      ),
    );
  }

  void setSummaryProvider(String value) {
    if (value == 'local' && !state.deviceSupportsLocal) {
      return;
    }
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          summaryProvider: AppPreferences.normalizeSummaryProvider(value),
        ),
      ),
    );
  }

  void setThemeMode(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          themeMode: AppPreferences.normalizeThemeMode(value),
        ),
      ),
    );
  }

  /// Persists the draft (with `hasSeenOnboarding = true`) and applies the chosen
  /// transcription language so the very first recording already uses it.
  Future<void> finish() async {
    if (state.saving) {
      return;
    }
    emit(state.copyWith(saving: true));
    final prefs = state.draft.copyWith(hasSeenOnboarding: true);
    _transcriptionService.setTranscriptionLanguage(prefs.transcriptionLanguage);
    await _transcriptRepository.savePreferences(prefs);
    emit(state.copyWith(saving: false, completed: true));
  }
}
