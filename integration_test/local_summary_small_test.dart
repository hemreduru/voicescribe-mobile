// On-device local-summary run for the small 300/500/1000-word corpus.
//
// Mirrors local_summary_corpus_test.dart but over the smaller buckets, and dumps
// every RAW model output as JSON to the app's external files dir so the host can
// pull it and replay it through the no-leak Dart test (proving the UI never shows
// raw JSON and tryParse never throws on real on-device output).
//
// Prereq: q8 Gemma model already downloaded (Settings → Summary → download).
// Run: flutter test integration_test/local_summary_small_test.dart -d <device>
import 'dart:convert';
import 'dart:io';

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
const int _inputBudget = 2200;

const List<String> _corpus = <String>[
  'n01_corporate_tr_300',
  'n02_healthcare_en_300',
  'n03_casual_mix_300_noise',
  'n04_tech_tr_500',
  'n05_legal_en_500',
  'n06_education_mix_500',
  'n07_education_tr_1000',
  'n08_corporate_en_1000',
  'n09_tech_mix_1000_noise',
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'on-device local summary over small corpus (mic bypassed)',
    (tester) async {
      await EnvConfig.initialize();
      await FlutterGemma.initialize();

      final support = await getApplicationSupportDirectory();
      // ignore: avoid_print
      print('MODEL_PATH=${support.path}/$_modelFile '
          'installed=${await FlutterGemma.isModelInstalled(_modelFile)}');

      final token = EnvConfig.huggingFaceToken;
      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(
            EnvConfig.llmModelDownloadUrl,
            token: token.isEmpty ? null : token,
          )
          .install();

      const runtime = LocalLlmRuntime();
      final locale = deviceLanguageCode();
      // ignore: avoid_print
      print('DEVICE_LOCALE=$locale');

      final raws = <Map<String, dynamic>>[];
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

        // tryParse must never throw on real on-device output.
        MeetingSummary? parsed;
        expect(() => parsed = MeetingSummary.tryParse(raw), returnsNormally,
            reason: 'tryParse threw for $id');

        // Mirror the exact _SummaryTab render-branch selection and assert the
        // user can NEVER be shown raw JSON.
        final looksJson = MeetingSummary.looksLikeJson(raw);
        final renderPath = parsed != null
            ? 'structured'
            : (looksJson ? 'clean-fallback' : 'plaintext');
        if (status == 'ok' && renderPath == 'plaintext') {
          expect(raw.contains('{'), isFalse,
              reason: 'JSON LEAK: $id would render raw braces as plain text');
        }
        if (parsed != null) {
          final p = parsed!;
          final fields = <String>[
            p.title,
            ...p.executiveSummary,
            ...p.decisions,
            ...p.openQuestions,
            ...p.notes,
            ...p.agendaItems.map((a) => a.title),
            ...p.agendaItems.map((a) => a.discussion),
            ...p.actionItems.map((a) => a.task),
          ];
          for (final f in fields) {
            expect(f.contains('{') || f.contains('"schema_version"'), isFalse,
                reason: 'rendered field leaked JSON for $id: "$f"');
          }
        }

        // ignore: avoid_print
        print('LOCALRES id=$id status=$status ms=${sw.elapsedMilliseconds} '
            'parsed=${parsed != null} render=$renderPath '
            'exec=${parsed?.executiveSummary.length ?? 0} '
            'dec=${parsed?.decisions.length ?? 0} '
            'act=${parsed?.actionItems.length ?? 0} '
            'recorderLeak=${raw.contains('"recorder"')} '
            'title=${parsed?.title ?? '-'}');
        final flat = raw.replaceAll('\n', ' ');
        // ignore: avoid_print
        print('LOCALRAW id=$id >>>'
            '${flat.substring(0, flat.length > 400 ? 400 : flat.length)}<<<');
        raws.add(<String, dynamic>{
          'id': id,
          'provider': 'local',
          'raw': status == 'ok' ? raw : null,
          'status': status,
          'ms': sw.elapsedMilliseconds,
        });
      }

      // Dump to external files dir (pullable without root):
      // /sdcard/Android/data/<pkg>/files/small_local_raw.json
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final out = File('${ext.path}/small_local_raw.json');
        await out.writeAsString(jsonEncode(raws));
        // ignore: avoid_print
        print('WROTE ${out.path}');
      }
    },
    timeout: const Timeout(Duration(minutes: 40)),
  );
}
