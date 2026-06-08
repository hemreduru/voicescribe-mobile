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

    test('looksLikeJson detects JSON hidden behind leading prose', () {
      // A weak model may prepend prose before the object — those raw braces
      // must NOT leak to the plain-text render path.
      expect(
        MeetingSummary.looksLikeJson('İşte toplantı özeti:\n{"title":"X"'),
        isTrue,
      );
      expect(
        MeetingSummary.looksLikeJson('Here is the summary: { "title": "X" }'),
        isTrue,
      );
      // Genuine prose without a JSON object stays plain text.
      expect(
        MeetingSummary.looksLikeJson('Toplantıda bütçe konuşuldu ve onaylandı.'),
        isFalse,
      );
    });

    test('recovers a JSON object hidden behind leading prose', () {
      const raw = 'İşte toplantı özeti:\n{"title":"Saha Denetimi","decisions":["Onaylandı"]}';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Saha Denetimi');
      expect(summary.decisions, ['Onaylandı']);
    });

    test('returns null for valid-but-empty JSON', () {
      expect(
        MeetingSummary.tryParse(jsonEncode({'metadata': <String, Object?>{}})),
        isNull,
      );
    });

    test('repairs truncation mid-string (model hit token cap)', () {
      // Gemma q8 routinely stops mid-value at the token cap, leaving an
      // unclosed string and unclosed object — recover the fields it did emit.
      const raw =
          '{"schema_version":1,"title":"Veritabanı Migrasyonu","executive_summary":"Bu toplantıda bellek sızıntı';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Veritabanı Migrasyonu');
      expect(summary.executiveSummary, hasLength(1));
      expect(summary.executiveSummary.single, startsWith('Bu toplantıda'));
    });

    test('repairs truncation mid-array (unclosed list + string)', () {
      const raw =
          '{"title":"Saha Toplantısı","executive_summary":["Birinci nokta","İkinci nokta","New equipment was re';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Saha Toplantısı');
      // The two complete items survive; the dangling one is closed too.
      expect(summary.executiveSummary.length, greaterThanOrEqualTo(2));
      expect(summary.executiveSummary, contains('Birinci nokta'));
      for (final s in summary.executiveSummary) {
        expect(s.contains('{'), isFalse);
        expect(s.contains('['), isFalse);
      }
    });

    test('repairs truncation after a dangling key with no value', () {
      const raw =
          '{"title":"Bütçe Görüşmesi","decisions":["Onaylandı"],"notes":';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Bütçe Görüşmesi');
      expect(summary.decisions, ['Onaylandı']);
      expect(summary.notes, isEmpty);
    });

    test('repairs truncation with a dangling trailing comma', () {
      const raw =
          '{"title":"Demo","executive_summary":["Tek madde"],"decisions":[],';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Demo');
      expect(summary.executiveSummary, ['Tek madde']);
    });

    test('repaired output never leaks raw JSON when content survives', () {
      // The contract that matters for the UI: if any field survives, the user
      // sees structured content, never a brace-laden string.
      const raw =
          '{"title":"Kalite Kontrol","agenda_items":[{"title":"Hat 3","discussion":"Duruş süreleri arttı';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Kalite Kontrol');
      expect(summary.agendaItems, isNotEmpty);
      expect(summary.agendaItems.first.title, 'Hat 3');
    });
  });

  group('MeetingSummary.tryParse — flexible action/agenda items', () {
    test('action_items as a string array becomes ActionItem.task', () {
      const raw =
          '{"title":"Toplantı","action_items":["Ali raporu yazsın","Veli sunum hazırlasın"]}';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.actionItems.map((a) => a.task), [
        'Ali raporu yazsın',
        'Veli sunum hazırlasın',
      ]);
    });

    test('action_items as a bare string becomes a single ActionItem', () {
      const raw = '{"title":"Toplantı","action_items":"Ali raporu yazsın"}';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.actionItems, hasLength(1));
      expect(summary.actionItems.first.task, 'Ali raporu yazsın');
    });

    test('action_items with a numeric due_date does not throw', () {
      const raw =
          '{"title":"T","action_items":[{"owner":"Ali","task":"Rapor","due_date":5}]}';
      MeetingSummary? summary;
      expect(() => summary = MeetingSummary.tryParse(raw), returnsNormally);
      expect(summary, isNotNull);
      expect(summary!.actionItems.first.owner, 'Ali');
      expect(summary!.actionItems.first.dueDate, '5');
    });

    test('agenda_items as a string array becomes AgendaItem.title', () {
      const raw =
          '{"title":"T","agenda_items":["Bütçe","Personel"],"decisions":["x"]}';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.agendaItems.map((a) => a.title), ['Bütçe', 'Personel']);
    });

    test('agenda_items as a bare string becomes a single AgendaItem', () {
      const raw = '{"title":"T","agenda_items":"Bütçe görüşmesi"}';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.agendaItems, hasLength(1));
      expect(summary.agendaItems.first.title, 'Bütçe görüşmesi');
    });
  });

  group('MeetingSummary.tryParse — near-JSON repair', () {
    test('trailing commas are tolerated', () {
      const raw =
          '{"title":"T","decisions":["a","b",],"action_items":[],}';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.decisions, ['a', 'b']);
    });

    test('smart quotes are normalized', () {
      const raw = '{“title”:“Stratejik Plan”}';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Stratejik Plan');
    });

    test('single-quoted JSON is recovered', () {
      const raw = "{'title':'Bütçe','decisions':['Onaylandı']}";
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Bütçe');
      expect(summary.decisions, ['Onaylandı']);
    });

    test('unquoted keys are recovered', () {
      const raw = '{title:"Saha Ziyareti",decisions:["Tamam"]}';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Saha Ziyareti');
    });

    test('NaN/Infinity values become null without throwing', () {
      const raw = '{"title":"T","subtitle":NaN,"next_meeting":Infinity}';
      MeetingSummary? summary;
      expect(() => summary = MeetingSummary.tryParse(raw), returnsNormally);
      expect(summary, isNotNull);
      expect(summary!.title, 'T');
      expect(summary!.subtitle, isNull);
    });

    test('control characters inside the payload are stripped', () {
      // A bell (0x07) byte injected mid-token would otherwise make
      // jsonDecode throw; the normalizer drops it.
      final raw = '{"title":"Te${String.fromCharCode(7)}st","decisions":["a"]}';
      MeetingSummary? summary;
      expect(() => summary = MeetingSummary.tryParse(raw), returnsNormally);
      expect(summary, isNotNull);
      expect(summary!.title, 'Test');
    });

    test('a JSON object wrapped in a root array is unwrapped', () {
      const raw = '[{"title":"Dizi Kökü","decisions":["a"]}]';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Dizi Kökü');
    });

    test('the first of several consecutive objects is used', () {
      const raw =
          '{"title":"Birinci","decisions":["a"]}{"title":"İkinci"}';
      final summary = MeetingSummary.tryParse(raw);
      expect(summary, isNotNull);
      expect(summary!.title, 'Birinci');
    });

    test('a bare string root never throws and yields null', () {
      MeetingSummary? summary;
      expect(
        () => summary = MeetingSummary.tryParse('sadece düz metin özet'),
        returnsNormally,
      );
      expect(summary, isNull);
    });
  });
}
