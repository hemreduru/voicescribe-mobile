import 'dart:async';

import 'package:voicescribe_mobile/data/services/llm/llm_model_service.dart';
import 'package:voicescribe_mobile/data/services/llm/local_llm_runtime.dart';
import 'package:voicescribe_mobile/domain/models/chat.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/domain/services/chat_prompt.dart';
import 'package:voicescribe_mobile/domain/utils/text_utils.dart';

/// Thrown when the on-device chat cannot produce an answer. Carries a
/// user-facing [message] (no class names / stacks).
class LocalChatException implements Exception {
  const LocalChatException(this.message);
  final String message;
  @override
  String toString() => 'LocalChatException: $message';
}

/// Answers chat questions fully on-device: retrieves the user's most relevant
/// local transcripts (keyword scoring over cached chunks), then asks the same
/// Gemma model used for local summaries to answer ONLY from those sources.
class LocalChatService {
  LocalChatService({
    required TranscriptRepository repository,
    required LocalLlmModelService modelService,
    LocalLlmRuntime runtime = const LocalLlmRuntime(),
  }) : _repository = repository,
       _modelService = modelService,
       _runtime = runtime;

  final TranscriptRepository _repository;
  final LocalLlmModelService _modelService;
  final LocalLlmRuntime _runtime;

  static const int _maxSources = 3;
  static const int _perSourceChars = 1500;
  static const Duration _timeout = Duration(minutes: 4);

  Future<({String answer, List<ChatSource> sources})> answer({
    required String question,
    required List<ChatMessage> history,
  }) async {
    final q = question.trim();
    if (q.isEmpty) {
      throw const LocalChatException('Lütfen bir soru yazın.');
    }

    final snapshot = await _repository.loadSnapshot();
    final retrieved = _retrieve(q, snapshot);

    final promptSources = retrieved
        .map(
          (r) => <String, String>{
            'title': r.title,
            'date': r.date ?? '',
            'text': r.text,
          },
        )
        .toList();

    final recent = history
        .where((m) => m.content.trim().isNotEmpty)
        .map((m) => (role: m.role, content: m.content))
        .toList();
    final boundedHistory = recent.length > 6
        ? recent.sublist(recent.length - 6)
        : recent;

    final userPrompt = ChatPrompt.buildUserPrompt(
      sources: promptSources,
      history: boundedHistory,
      question: q,
    );

    await _modelService.ensureReady();

    final String raw;
    try {
      raw = await _runtime
          .generate(
            systemInstruction: ChatPrompt.system(),
            userText: userPrompt,
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const LocalChatException(
        'Yanıt beklenenden uzun sürdü. Lütfen tekrar deneyin veya Bulut moduna geçin.',
      );
    } catch (_) {
      throw const LocalChatException(
        'Cihaz üstü yapay zekâ şu an yanıt veremedi. Lütfen tekrar deneyin.',
      );
    }

    final cleaned = raw.trim();
    if (cleaned.isEmpty) {
      throw const LocalChatException(
        'Boş bir yanıt alındı. Lütfen tekrar deneyin.',
      );
    }

    final sources = retrieved
        .map((r) => ChatSource(title: r.title, date: r.date))
        .toList();
    return (answer: cleaned, sources: sources);
  }

  List<({String title, String? date, String text})> _retrieve(
    String query,
    TranscriptSnapshot snapshot,
  ) {
    // Group chunk text per transcript.
    final textByTranscript = <String, StringBuffer>{};
    for (final chunk in snapshot.chunks) {
      (textByTranscript[chunk.transcriptId] ??= StringBuffer())
        ..write(chunk.text)
        ..write(' ');
    }

    final terms = normalizeWhitespace(query)
        .toLowerCase()
        .split(RegExp(r'[^\wçğıöşüâîû]+'))
        .where((t) => t.trim().length >= 3)
        .toSet();

    final scored = <({Transcript t, String text, int score})>[];
    for (final t in snapshot.transcripts) {
      final body = (textByTranscript[t.id]?.toString() ?? '').trim();
      if (body.isEmpty) {
        continue;
      }
      final haystack = '${t.title ?? ''} $body'.toLowerCase();
      var score = 0;
      for (final term in terms) {
        score += term.allMatches(haystack).length;
      }
      scored.add((t: t, text: body, score: score));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      // Tie-break: most recent first.
      return (b.t.recordedAt ?? b.t.createdAt).compareTo(
        a.t.recordedAt ?? a.t.createdAt,
      );
    });

    // If nothing matched keywords, fall back to the most recent transcripts so
    // the assistant still has context (mirrors the backend retriever).
    final hits = scored.where((s) => s.score > 0).toList();
    final chosen = (hits.isNotEmpty ? hits : scored).take(_maxSources);

    return chosen.map((s) {
      final text = s.text.length > _perSourceChars
          ? s.text.substring(0, _perSourceChars)
          : s.text;
      return (
        title: (s.t.title ?? '').trim().isEmpty ? 'Adsız kayıt' : s.t.title!,
        date: (s.t.recordedAt ?? s.t.createdAt)
            .toIso8601String()
            .split('T')
            .first,
        text: text,
      );
    }).toList();
  }
}
