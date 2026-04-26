class AppStrings {
  const AppStrings();

  String get appName => 'VoiceScribe';
  String get recording => 'Kayıt';
  String get transcript => 'Transkript';
  String get summary => 'Özet';
  String get history => 'Geçmiş';
  String get speaker => 'Konuşmacı';
  String get bootstrapTitle => 'VoiceScribe hazırlanıyor';
  String get bootstrapMessage => 'Cihaz içi Whisper modeli yükleniyor...';
  String get bootstrapFailed => 'Model kurulumu başarısız oldu.';
  String get retrySetup => 'Tekrar Dene';
  String get downloadingModel => 'Model indiriliyor';
  String get modelReady => 'AI Hazır';
  String get modelLoading => 'Model yükleniyor...';
  String get tapToRecord => 'Kayıt başlatmak için butona dokunun';
  String get isRecording => 'Kaydediliyor';
  String get recordingPaused => 'Kayıt duraklatıldı';
  String get sessionNamePlaceholder => 'Oturum adı girin...';
  String get pause => 'Duraklat';
  String get resume => 'Devam Et';
  String get stop => 'Durdur';
  String get recentRecordings => 'Son Kayıtlar';
  String get viewAll => 'Tümünü Gör';
  String get noRecordings => 'Henüz kayıt bulunmuyor';
  String get searchRecordings => 'Kayıtlarda ara...';
  String get noTranscriptAvailable => 'Transkript mevcut değil.';
  String get noMatchingText => 'Eşleşen metin bulunamadı.';
  String get copy => 'Kopyala';
  String get export => 'Dışa Aktar';
  String get edit => 'Düzenle';
  String get local => 'Yerel';
  String get cloud => 'Bulut';
  String get short => 'Kısa';
  String get medium => 'Orta';
  String get long => 'Uzun';
  String get generateSummary => 'Özet Oluştur';
  String get summaryPlaceholder =>
      'Özetleme motoru Flutter iskeletinde hazır. Yerel LLM veya bulut sağlayıcı bağlandığında burada sonuç üretilecek.';
  String get speakerRecognition => 'Konuşmacı Tanıma';
  String get speakerRecognitionDesc =>
      'Kayıtlardaki konuşmacıları otomatik olarak tanımla ve etiketle.';
  String get addNewSpeaker => 'Konuşmacı Ekle';
  String get registeredSpeakers => 'Kayıtlı Konuşmacılar';
  String get recordVoiceSample => 'Ses örneği kaydet';
  String get voiceSampleAvailable => 'Ses örneği var';
  String get unnamed => 'Adsız';
  String get delete => 'Sil';
  String get cancel => 'İptal';
  String get permissionDenied => 'Mikrofon izni gerekli.';

  String statusLabel(String key) {
    switch (key) {
      case 'recording':
        return 'Kaydediliyor';
      case 'transcribing':
        return 'Çevriliyor';
      case 'completed':
        return 'Tamamlandı';
      case 'transcription_error':
        return 'Hata';
      default:
        return 'Boş Kayıt';
    }
  }
}
