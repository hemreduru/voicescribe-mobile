import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/domain/models/meeting_summary.dart';

void main() {
  group('MeetingSummary.tryParse', () {
    test('parses a complete meeting-minutes JSON', () {
      final raw = jsonEncode({
        'schema_version': 1,
        'title': 'Sprint Planlama',
        'subtitle': 'Q3 yol haritası',
        'metadata': {
          'topic': 'Sprint',
          'date': '2026-06-06',
          'start_time': '10:00',
          'end_time': '11:00',
          'location': 'Zoom',
          'attendees': ['Ahmet', 'Ayşe'],
          'absentees': ['Mehmet'],
          'recorder': 'Ayşe',
        },
        'executive_summary': ['Bütçe onaylandı.', 'Lansman ertelendi.'],
        'agenda_items': [
          {
            'title': 'Bütçe',
            'discussion': 'Tartışıldı.',
            'conclusion': 'Onaylandı.',
          },
        ],
        'decisions': ['Lansman Eylül ayına ertelendi.'],
        'action_items': [
          {'owner': 'Ahmet', 'task': 'Mali tablo', 'due_date': '2026-06-15'},
        ],
        'open_questions': ['Pazarlama bütçesi?'],
        'next_meeting': '2026-06-13',
        'notes': ['Rakam net değil.'],
      });

      final summary = MeetingSummary.tryParse(raw);

      expect(summary, isNotNull);
      expect(summary!.title, 'Sprint Planlama');
      expect(summary.metadata.attendees, ['Ahmet', 'Ayşe']);
      expect(summary.metadata.absentees, ['Mehmet']);
      expect(summary.executiveSummary, hasLength(2));
      expect(summary.agendaItems.single.conclusion, 'Onaylandı.');
      expect(summary.actionItems.single.owner, 'Ahmet');
      expect(summary.decisions.single, 'Lansman Eylül ayına ertelendi.');
      expect(summary.nextMeeting, '2026-06-13');
    });

    test('returns null for legacy plain-text summaries', () {
      expect(MeetingSummary.tryParse('- bir madde\n- iki madde'), isNull);
      expect(MeetingSummary.tryParse(''), isNull);
      expect(MeetingSummary.tryParse('Bu düz metin bir özet.'), isNull);
    });

    test('strips ```json code fences before parsing', () {
      final fenced =
          '```json\n${jsonEncode({'title': 'Toplantı', 'decisions': <Object?>[]})}\n```';
      final summary = MeetingSummary.tryParse(fenced);
      expect(summary, isNotNull);
      expect(summary!.title, 'Toplantı');
    });

    test('tolerates partial JSON with missing/defaulted fields', () {
      final summary = MeetingSummary.tryParse(
        jsonEncode({'title': 'Kısmi', 'decisions': ['Tek karar']}),
      );
      expect(summary, isNotNull);
      expect(summary!.title, 'Kısmi');
      expect(summary.executiveSummary, isEmpty);
      expect(summary.agendaItems, isEmpty);
      expect(summary.metadata.attendees, isEmpty);
    });

    test('coerces a bare string into a single-element list', () {
      final summary = MeetingSummary.tryParse(
        jsonEncode({
          'title': 'Esnek',
          'executive_summary': 'Tek cümlelik özet.',
          'decisions': 'Tek karar metni.',
        }),
      );
      expect(summary, isNotNull);
      expect(summary!.executiveSummary, ['Tek cümlelik özet.']);
      expect(summary.decisions, ['Tek karar metni.']);
    });

    test('renders object items in string lists without raw map braces', () {
      // Small local models sometimes emit action-item objects inside the
      // decisions array; surface a meaningful field, never "{owner: ...}".
      final summary = MeetingSummary.tryParse(
        jsonEncode({
          'title': 'Vizit',
          'decisions': [
            {
              'owner': 'Doktor',
              'task': 'Ameliyat planını değiştir',
              'due_date': 'Salı',
            },
            'Düz karar',
          ],
        }),
      );
      expect(summary, isNotNull);
      expect(summary!.decisions, ['Ameliyat planını değiştir', 'Düz karar']);
      for (final d in summary.decisions) {
        expect(d.contains('{'), isFalse, reason: 'no raw map braces: $d');
      }
    });

    test('extracts JSON despite trailing model garbage (repetition loop)', () {
      final raw =
          '${jsonEncode({'title': 'Toplantı', 'decisions': <Object?>['Karar']})}'
          '2222222222222222222222222';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Toplantı');
      expect(summary.decisions, ['Karar']);
    });

    test('strips <think> reasoning before the JSON', () {
      final raw =
          '<think>Let me analyze the meeting...</think>\n'
          '${jsonEncode({'title': 'Sprint', 'decisions': <Object?>['X ertelendi']})}';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Sprint');
    });

    test('pure repetition garbage returns null (no crash)', () {
      expect(MeetingSummary.tryParse('2222222222222222'), isNull);
      expect(MeetingSummary.looksLikeJson('2222222222'), isFalse);
    });

    test('looksLikeJson detects intended-but-broken JSON', () {
      expect(MeetingSummary.looksLikeJson('{"title": "x" 2222'), isTrue);
      expect(MeetingSummary.looksLikeJson('- legacy bullet'), isFalse);
    });

    test('returns null for valid-but-empty JSON', () {
      expect(
        MeetingSummary.tryParse(jsonEncode({'metadata': <String, Object?>{}})),
        isNull,
      );
    });
  });
}
