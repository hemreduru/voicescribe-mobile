// On-device local-summary stress test.
//
// Runs the real on-device Gemma 3 1B (int8/q8) summarizer over a corpus of
// meeting transcripts (Turkish, English, mixed and deliberate Whisper-garbage),
// bypassing the recording/transcription UI. It loads the already-installed model
// directly from disk (fromFile) so it needs no backend round-trip, then prints
// per-transcript results (parse success, output language, section counts, recorder
// leak check, timing) for inspection.
//
// Prereq: the q8 Gemma model must already be downloaded on the device (Settings →
// Summary → download), living at <appSupport>/Gemma3-1B-IT_..._q8_ekv4096.task.
//
// Run: flutter test integration_test/local_summary_corpus_test.dart -d <device>
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voicescribe_mobile/data/services/llm/local_llm_runtime.dart';
import 'package:voicescribe_mobile/domain/models/meeting_summary.dart';
import 'package:voicescribe_mobile/domain/services/meeting_minutes_prompt.dart';
import 'package:voicescribe_mobile/domain/utils/locale_utils.dart';
import 'package:voicescribe_mobile/ui/core/utils/env_config.dart';

const String _modelFile = 'Gemma3-1B-IT_multi-prefill-seq_q8_ekv4096.task';
// Mirrors LocalLlmSummaryService's input cap (small local context window).
const int _inputBudget = 2200;

// Same subset bundled under test_assets/corpus/.
const List<String> _corpus = <String>[
  't01_corporate_tr_500', // TR, coherent
  't02_corporate_en_1500', // EN -> expect TR output (translation)
  't03_tech_mixed_2500', // TR/EN mixed
  't11_casual_tr_1500_noise', // Whisper garbage (TR)
  't06_education_tr_15000', // huge -> truncated, must not crash
];

String _detectLang(String s) {
  final lower = s.toLowerCase();
  final tr = RegExp('[ğşıçöü]').allMatches(lower).length +
      RegExp(r'\b(ve|bir|için|olarak|toplantı|karar|öğrenci|hasta|belirtildi)\b')
              .allMatches(lower)
              .length *
          3;
  final en = RegExp(r'\b(the|and|was|were|meeting|budget|patient|student|decided)\b')
          .allMatches(lower)
          .length *
      3;
  if (tr == 0 && en == 0) return 'unknown';
  return tr >= en ? 'tr' : 'en';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'on-device local summary over corpus (mic bypassed)',
    (tester) async {
      await EnvConfig.initialize();
      await FlutterGemma.initialize();

      final support = await getApplicationSupportDirectory();
      // ignore: avoid_print
      print('MODEL_PATH=${support.path}/$_modelFile '
          'installed=${await FlutterGemma.isModelInstalled(_modelFile)}');

      // Mirror the app's ensureReady(): fromNetwork() install is idempotent and
      // skips the download when the file is already present, then sets it active.
      // The HF token is passed via --dart-define (never committed).
      final token = EnvConfig.huggingFaceToken;
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      )
          .fromNetwork(
            EnvConfig.llmModelDownloadUrl,
            token: token.isEmpty ? null : token,
          )
          .install();

      const runtime = LocalLlmRuntime();
      final locale = deviceLanguageCode();
      // ignore: avoid_print
      print('DEVICE_LOCALE=$locale');

      for (final id in _corpus) {
        final text = await rootBundle.loadString('test_assets/corpus/$id.txt');
        final bounded =
            text.length > _inputBudget ? text.substring(0, _inputBudget) : text;
        final prompt = MeetingMinutesPrompt.system(locale: locale);

        final sw = Stopwatch()..start();
        String raw;
        String status;
        try {
          raw = await runtime.generate(
            systemInstruction: prompt,
            userText: bounded,
          );
          status = 'ok';
        } catch (e) {
          raw = 'ERR: $e';
          status = 'error';
        }
        sw.stop();

        final parsed = MeetingSummary.tryParse(raw);
        final lang = parsed == null
            ? 'n/a'
            : _detectLang('${parsed.title} ${parsed.executiveSummary.join(' ')}');
        // ignore: avoid_print
        print('LOCALRES id=$id status=$status ms=${sw.elapsedMilliseconds} '
            'parsed=${parsed != null} lang=$lang '
            'exec=${parsed?.executiveSummary.length ?? 0} '
            'dec=${parsed?.decisions.length ?? 0} '
            'act=${parsed?.actionItems.length ?? 0} '
            'recorderLeak=${raw.contains('"recorder"')} '
            'title=${parsed?.title ?? '-'}');
        final flat = raw.replaceAll('\n', ' ');
        // ignore: avoid_print
        print('LOCALRAW id=$id >>>'
            '${flat.substring(0, flat.length > 500 ? 500 : flat.length)}<<<');
      }
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
