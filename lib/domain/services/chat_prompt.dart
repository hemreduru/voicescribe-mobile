/// On-device RAG chat prompt — mirrors the backend ChatPrompt
/// (app/Services/Chat/ChatPrompt.php) so the local model answers ONLY from the
/// user's own transcripts and cites them, instead of hallucinating.
class ChatPrompt {
  const ChatPrompt._();

  static String system() {
    return 'Sen, kullanıcının kendi ses kayıtlarından çıkarılmış transkriptler '
        'üzerinde soru yanıtlayan bir asistansın. SADECE sana verilen kaynak '
        'alıntılarına dayanarak yanıt ver.\n'
        'Kurallar:\n'
        '- Yalnızca aşağıdaki kaynaklardaki bilgiyi kullan; bilgi UYDURMA.\n'
        '- Kaynaklarda olmayan bir şey sorulursa açıkça '
        '"Kayıtlarında bu konuda bir bilgi bulamadım." de.\n'
        '- Kullandığın bilginin kaynağını cümle içinde belirt: '
        '(Kaynak: "<başlık>").\n'
        '- Kısa, doğrudan ve Türkçe yanıt ver.';
  }

  /// Builds the user turn with the retrieved [sources], recent [history] and the
  /// [question]. Each source is `{title, date, text}`.
  static String buildUserPrompt({
    required List<Map<String, String>> sources,
    required List<({String role, String content})> history,
    required String question,
  }) {
    final parts = <String>[];

    if (sources.isEmpty) {
      parts.add('KAYNAKLAR: (ilgili transkript bulunamadı)');
    } else {
      parts.add('KAYNAKLAR:');
      for (var i = 0; i < sources.length; i++) {
        final s = sources[i];
        final date = (s['date'] ?? '').isEmpty ? 'tarih yok' : s['date'];
        parts.add('[${i + 1}] Başlık: "${s['title']}" | Tarih: $date\n${s['text']}');
      }
    }

    if (history.isNotEmpty) {
      parts.add('\nÖNCEKİ KONUŞMA:');
      for (final m in history) {
        final who = m.role == 'assistant' ? 'Asistan' : 'Kullanıcı';
        parts.add('$who: ${m.content}');
      }
    }

    parts.add('\nSORU: $question');
    parts.add('Yukarıdaki kaynaklara dayanarak yanıtla ve kullandığın '
        'kaynakları belirt.');

    return parts.join('\n');
  }
}
