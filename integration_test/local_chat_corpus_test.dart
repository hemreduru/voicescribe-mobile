// On-device local CHAT hallucination matrix.
//
// Runs the on-device RAG chat path (retrieve over cached transcripts + Gemma)
// over every seeded transcript with a LOGICAL (answerable) and an ILLOGICAL
// (absent) question, classifying refusals — to measure hallucination locally.
// Loads the installed model directly (no backend auth needed) and mirrors
// LocalChatService's retrieve+prompt+generate flow.
//
// Run: flutter test integration_test/local_chat_corpus_test.dart -d <device> \
//        --dart-define=HUGGING_FACE_TOKEN=<hf>
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:voicescribe_mobile/data/repositories/sqflite_transcript_repository.dart';
import 'package:voicescribe_mobile/data/services/llm/local_llm_runtime.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/services/chat_prompt.dart';
import 'package:voicescribe_mobile/ui/core/utils/env_config.dart';

// (logical, illogical) ASCII-safe questions so keyword retrieval matches.
const Map<String, List<String>> _questions = {
  'Kurumsal (corporate)': [
    'Lansman hangi aya ertelendi',
    'Toplantida hangi hayvan getirildi',
  ],
  'Teknik (tech)': ['API gecikmesi kac milisaniye', 'Ekip hangi tatile gitti'],
  'Egitim (education)': [
    'Ikinci dunya savasi ne zaman basladi',
    'Ogretmenin dogum gunu ne zaman',
  ],
  'Saglik (healthcare)': [
    'Antibiyotik dozu nedir',
    'Hastanin dogum gunu ne zaman',
  ],
  'Hukuk (legal)': ['Sozlesme suresi kac ay', 'Avukatin arabasi ne renk'],
  'Gunluk-gurultu (casual)': [
    'Bakiye ne kadar',
    'Mars yolculugu kac gun surdu',
  ],
};

bool _refused(String a) => RegExp(
  'bulamad[ıi]m|bilgi (yok|bulun)|kay[ıi]tlar[ıi]nda',
  caseSensitive: false,
).hasMatch(a);

List<Map<String, String>> _retrieve(String query, TranscriptSnapshot snap) {
  final byT = <String, StringBuffer>{};
  for (final c in snap.chunks) {
    (byT[c.transcriptId] ??= StringBuffer()).write('${c.text} ');
  }
  final terms = query
      .toLowerCase()
      .split(RegExp(r'[^\wçğıöşü]+'))
      .where((t) => t.length >= 3)
      .toSet();
  final scored = <({Transcript t, String text, int score})>[];
  for (final t in snap.transcripts) {
    final body = (byT[t.id]?.toString() ?? '').trim();
    if (body.isEmpty) continue;
    final hay = '${t.title ?? ''} $body'.toLowerCase();
    var s = 0;
    for (final term in terms) {
      s += term.allMatches(hay).length;
    }
    scored.add((t: t, text: body, score: s));
  }
  scored.sort((a, b) => b.score.compareTo(a.score));
  final hits = scored.where((s) => s.score > 0).toList();
  final chosen = (hits.isNotEmpty ? hits : scored).take(3);
  return chosen
      .map(
        (s) => {
          'title': (s.t.title ?? 'Adsız kayıt'),
          'date': (s.t.recordedAt ?? s.t.createdAt)
              .toIso8601String()
              .split('T')
              .first,
          'text': s.text.length > 1500 ? s.text.substring(0, 1500) : s.text,
        },
      )
      .toList();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'on-device local chat hallucination matrix',
    (tester) async {
      await EnvConfig.initialize();
      await FlutterGemma.initialize();
      final token = EnvConfig.huggingFaceToken;
      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(
            EnvConfig.llmModelDownloadUrl,
            token: token.isEmpty ? null : token,
          )
          .install();

      final runtime = LocalLlmRuntime();
      final repo = SqfliteTranscriptRepository();
      final snap = await repo.loadSnapshot();
      // ignore: avoid_print
      print(
        'SNAPSHOT transcripts=${snap.transcripts.length} chunks=${snap.chunks.length}',
      );

      for (final entry in _questions.entries) {
        final category = entry.key;
        for (final pair in [
          ('logical', entry.value[0]),
          ('illogical', entry.value[1]),
        ]) {
          final kind = pair.$1;
          final q = pair.$2;
          final sources = _retrieve(q, snap);
          final prompt = ChatPrompt.buildUserPrompt(
            sources: sources,
            history: const [],
            question: q,
          );
          final sw = Stopwatch()..start();
          String raw;
          try {
            raw = await runtime
                .generate(
                  systemInstruction: ChatPrompt.system(),
                  userText: prompt,
                )
                .timeout(const Duration(minutes: 4));
          } catch (e) {
            raw = 'ERR: $e';
          }
          sw.stop();
          final flat = raw.replaceAll('\n', ' ');
          // ignore: avoid_print
          print(
            'LCHAT cat="$category" kind=$kind refused=${_refused(raw)} '
            'ms=${sw.elapsedMilliseconds} srcs=${sources.length} '
            'q="$q" a="${flat.substring(0, flat.length > 240 ? 240 : flat.length)}"',
          );
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 100)),
  );
}
