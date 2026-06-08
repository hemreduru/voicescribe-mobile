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
    const schema =
        '{"schema_version":$kMeetingSummarySchemaVersion,"title":"kısa başlık","executive_summary":["2-4 cümle, her biri ayrı"],"decisions":["alınan kararlar"],"action_items":[{"owner":"kişi veya null","task":"yapılacak iş","due_date":"tarih veya null"}],"open_questions":["karara bağlanmayan konular"]}';
    final language = _languageName(locale);
    return '''
Sen deneyimli bir toplantı tutanağı yazarısın. Verilen toplantı transkriptini özetle ve SADECE aşağıdaki JSON nesnesini döndür (markdown, kod bloğu veya açıklama YOK). Tüm çıktıyı $language dilinde yaz; transkript hangi dilde olursa olsun içeriği $language diline çevir. Özel isimleri ve sayıları olduğu gibi koru.
Şema:
$schema
Kurallar: tarafsız ve geçmiş zaman kullan; kararları net ve tek cümle yaz; bilgi yoksa boş liste [] veya null kullan; bilgi uydurma; selamlaşma ve konu dışı sohbeti atla.''';
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
