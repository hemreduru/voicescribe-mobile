import 'package:voicescribe_mobile/domain/models/meeting_summary.dart';

/// Compact on-device prompt for the small local model (Qwen2.5 0.5B, ~1280 token
/// context). Asks tersely for the core MeetingSummary fields as JSON; the UI fills
/// defaults for and hides any sections the model omits. The cloud path uses the
/// richer backend prompt (app/Services/Summarization/MeetingMinutesPrompt.php).
class MeetingMinutesPrompt {
  const MeetingMinutesPrompt._();

  /// System instruction handed to the on-device model. [locale] is the user's
  /// phone language; the summary is written in that language regardless of the
  /// transcript's language.
  static String system({String locale = 'tr'}) {
    // A single concrete example doubles as the schema spec — for a small model a
    // filled example anchors valid-JSON output more reliably than abstract field
    // descriptions, and is ~24% shorter than the prior prose+schema+rules form.
    const example =
        '{"schema_version":$kMeetingSummarySchemaVersion,"title":"Bütçe Toplantısı","executive_summary":["Bütçe 50 bin TL olarak onaylandı.","Rapor cuma günü gönderilecek."],"decisions":["Bütçe 50 bin TL olarak onaylandı."],"action_items":[{"owner":"Ayşe","task":"Raporu gönder","due_date":"Cuma"}],"open_questions":["Tedarikçi seçimi netleşmedi"]}';
    final language = _languageName(locale);
    return '''
Toplantı transkriptini özetle ve SADECE aşağıdaki örnekteki gibi tek bir JSON döndür (markdown/açıklama YOK, tüm alanları doldur). Çıktı dili: $language.
Örnek: $example
Kurallar: geçmiş zaman; her kararı tek cümle; bilgi yoksa [] veya null; bilgi uydurma; selamlaşmayı atla.''';
  }

  /// System instruction for the **map** step of long-transcript summarization:
  /// condenses one window into short plain-text notes (not JSON) that the reduce
  /// step later folds into the final [MeetingSummary]. Plain notes keep each
  /// inference small and cheap to merge.
  static String partialNotes({String locale = 'tr'}) {
    final language = _languageName(locale);
    return '''
Sen bir toplantı transkriptinin BİR BÖLÜMÜNÜ işliyorsun. Bu bölümdeki önemli noktaları kısa madde işaretleriyle çıkar: kararlar, yapılacak işler (kim, ne, ne zaman) ve açık konular. SADECE düz metin madde listesi yaz (JSON, başlık veya açıklama YOK). Tümünü $language dilinde yaz. Bilgi uydurma; bu bölümde yoksa atla. Selamlaşma ve konu dışı sohbeti yok say.''';
  }

  /// Maps an app locale code to its Turkish language name for the prompt.
  static String _languageName(String locale) {
    final code = locale.trim().toLowerCase();
    final lang = code.length >= 2 ? code.substring(0, 2) : code;
    return switch (lang) {
      'en' => 'İngilizce',
      'de' => 'Almanca',
      'fr' => 'Fransızca',
      'es' => 'İspanyolca',
      'ar' => 'Arapça',
      'ru' => 'Rusça',
      _ => 'Türkçe',
    };
  }
}
