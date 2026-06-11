@Tags(['corpus'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/domain/models/meeting_summary.dart';

/// Empirical no-leak guarantee over REAL model outputs.
///
/// Replays every raw summary the cloud (and, when present, on-device) models
/// produced for the 300/500/1000-word corpus through the exact decision path the
/// UI uses in `_SummaryTab`, and asserts the user can NEVER see raw JSON and the
/// parser NEVER throws.
///
/// Driven by JSON files written by the corpus runners under /tmp/vs_corpus.
/// Skips cleanly when those files are absent (so CI without the corpus passes).
/// Run explicitly: `flutter test test/no_json_leak_corpus_test.dart --tags corpus`.
void main() {
  group('no JSON leak over real model outputs', () {
    final sources = <String, String>{
      'cloud': '/tmp/vs_corpus/small_cloud_raw.json',
      'local': '/tmp/vs_corpus/small_local_raw.json',
    };

    var any = false;
    for (final entry in sources.entries) {
      final file = File(entry.value);
      if (!file.existsSync()) continue;
      // Treat an empty or unparseable dump as absent (a runner may have created
      // the file before writing any rows) so the suite skips cleanly.
      final contents = file.readAsStringSync().trim();
      if (contents.isEmpty) continue;
      final List<Map<String, dynamic>> rows;
      try {
        rows = (jsonDecode(contents) as List).cast<Map<String, dynamic>>();
      } catch (_) {
        continue;
      }
      any = true;

      for (final row in rows) {
        final id = row['id'] as String;
        final raw = row['raw'] as String?;
        if (raw == null) continue; // provider errored upstream; nothing to render

        test('${entry.key}/$id renders safely (no raw JSON, no throw)', () {
          // 1. tryParse must never throw on arbitrary model output.
          MeetingSummary? structured;
          expect(
            () => structured = MeetingSummary.tryParse(raw),
            returnsNormally,
          );

          // 2. Mirror the exact _SummaryTab branch selection.
          final looksJson = MeetingSummary.looksLikeJson(raw);
          final String renderPath;
          if (structured != null) {
            renderPath = 'structured';
          } else if (looksJson) {
            renderPath = 'clean-fallback';
          } else {
            renderPath = 'plaintext';
          }

          // 3. The plaintext path must NEVER carry JSON braces to the user.
          if (renderPath == 'plaintext') {
            expect(
              raw.contains('{'),
              isFalse,
              reason: 'JSON LEAK: $id would render raw braces as plain text',
            );
          }

          // 4. If structured, no rendered string field may contain raw braces.
          if (structured != null) {
            final s = structured!;
            final strings = <String>[
              s.title,
              s.subtitle ?? '',
              ...s.executiveSummary,
              ...s.decisions,
              ...s.openQuestions,
              ...s.notes,
              ...s.metadata.attendees,
              ...s.metadata.absentees,
              ...s.agendaItems.map((a) => a.title),
              ...s.agendaItems.map((a) => a.discussion),
              ...s.actionItems.map((a) => a.task),
            ];
            for (final str in strings) {
              expect(
                str.contains('{') || str.contains('"schema_version"'),
                isFalse,
                reason: 'rendered field leaked JSON for $id: "$str"',
              );
            }
          }
        });
      }
    }

    test('corpus raw files were present', () {
      expect(
        any,
        isTrue,
        reason: 'no corpus raw files under /tmp/vs_corpus — run the runners',
      );
    }, skip: any ? false : 'corpus not generated in this environment');
  });
}
