import 'package:voicescribe_mobile/domain/models/meeting_summary.dart';

/// Compact on-device prompt for the small local model (Qwen2.5 0.5B, ~1280 token
/// context). Asks tersely for the core MeetingSummary fields as JSON; the UI fills
/// defaults for and hides any sections the model omits. The cloud path uses the
/// richer backend prompt (app/Services/Summarization/MeetingMinutesPrompt.php).
class MeetingMinutesPrompt {
  const MeetingMinutesPrompt._();

  /// System instruction handed to the on-device model.
  static String system({String length = 'medium'}) {
    const schema =
        '{"schema_version":$kMeetingSummarySchemaVersion,"title":"kısa başlık","executive_summary":["2-4 cümle, her biri ayrı"],"decisions":["alınan kararlar"],"action_items":[{"owner":"kişi veya null","task":"yapılacak iş","due_date":"tarih veya null"}],"open_questions":["karara bağlanmayan konular"]}';
    return '''
Sen deneyimli bir toplantı tutanağı yazarısın. Verilen toplantı transkriptini özetle ve SADECE aşağıdaki JSON nesnesini döndür (markdown, kod bloğu veya açıklama YOK). Metni transkriptin dilinde yaz.
Şema:
$schema
Kurallar: tarafsız ve geçmiş zaman kullan; kararları net ve tek cümle yaz; bilgi yoksa boş liste [] veya null kullan; bilgi uydurma; selamlaşma ve konu dışı sohbeti atla.''';
  }
}
