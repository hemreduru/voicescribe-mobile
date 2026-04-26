// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'VoiceScribe';

  @override
  String get recording => 'Kayıt';

  @override
  String get transcript => 'Transkript';

  @override
  String get summary => 'Özet';

  @override
  String get history => 'Geçmiş';

  @override
  String get speaker => 'Konuşmacı';

  @override
  String get bootstrapTitle => 'VoiceScribe hazırlanıyor';

  @override
  String get bootstrapMessage => 'Cihaz içi Whisper modeli yükleniyor...';

  @override
  String get bootstrapFailed => 'Model kurulumu başarısız oldu.';

  @override
  String get retrySetup => 'Tekrar Dene';

  @override
  String get downloadingModel => 'Model indiriliyor';

  @override
  String get modelReady => 'AI Hazır';

  @override
  String get modelLoading => 'Model yükleniyor...';

  @override
  String get tapToRecord => 'Kayıt başlatmak için butona dokunun';

  @override
  String get isRecording => 'Kaydediliyor';

  @override
  String get recordingPaused => 'Kayıt duraklatıldı';

  @override
  String get liveTranscript => 'Canlı Transkript';

  @override
  String get recordingStatus => 'Oturum Durumu';

  @override
  String get sessionNamePlaceholder => 'Oturum adı girin...';

  @override
  String get pause => 'Duraklat';

  @override
  String get resume => 'Devam Et';

  @override
  String get stop => 'Durdur';

  @override
  String get recentRecordings => 'Son Kayıtlar';

  @override
  String get noRecordings => 'Henüz kayıt bulunmuyor';

  @override
  String get searchRecordings => 'Kayıtlarda ara...';

  @override
  String get noTranscriptAvailable => 'Transkript mevcut değil.';

  @override
  String get noMatchingText => 'Eşleşen metin bulunamadı.';

  @override
  String get copy => 'Kopyala';

  @override
  String get export => 'Dışa Aktar';

  @override
  String get edit => 'Düzenle';

  @override
  String get local => 'Yerel';

  @override
  String get cloud => 'Bulut';

  @override
  String get short => 'Kısa';

  @override
  String get medium => 'Orta';

  @override
  String get long => 'Uzun';

  @override
  String get settings => 'Ayarlar';

  @override
  String get summarySettings => 'Özet Ayarları';

  @override
  String get latestTranscript => 'Son Transkript';

  @override
  String get readyToSummarize => 'Özet için hazır';

  @override
  String get generateSummary => 'Özet Oluştur';

  @override
  String get summaryPlaceholder =>
      'Özetleme motoru Flutter iskeletinde hazır. Yerel LLM veya bulut sağlayıcı bağlandığında burada sonuç üretilecek.';

  @override
  String get noSummaryYet => 'Üretilmiş özet henüz yok.';

  @override
  String get chunks => 'Parçalar';

  @override
  String get duration => 'Süre';

  @override
  String get selected => 'Seçildi';

  @override
  String get speakerRecognition => 'Konuşmacı Tanıma';

  @override
  String get speakerRecognitionDesc =>
      'Kayıtlardaki konuşmacıları otomatik olarak tanımla ve etiketle.';

  @override
  String get addNewSpeaker => 'Konuşmacı Ekle';

  @override
  String get registeredSpeakers => 'Kayıtlı Konuşmacılar';

  @override
  String get recordVoiceSample => 'Ses örneği kaydet';

  @override
  String get voiceSampleAvailable => 'Ses örneği var';

  @override
  String get unnamed => 'Adsız';

  @override
  String get delete => 'Sil';

  @override
  String get cancel => 'İptal';

  @override
  String get permissionDenied => 'Mikrofon izni gerekli.';

  @override
  String get statusRecording => 'Kaydediliyor';

  @override
  String get statusTranscribing => 'Çevriliyor';

  @override
  String get statusCompleted => 'Tamamlandı';

  @override
  String get statusTranscriptionError => 'Hata';

  @override
  String get statusEmpty => 'Boş Kayıt';

  @override
  String get newest => 'Yeni';

  @override
  String get oldest => 'Eski';

  @override
  String get longest => 'Uzun';

  @override
  String get localBadge => 'Yerel';

  @override
  String get transcriptBadge => 'Transkript';

  @override
  String get active => 'Aktif';

  @override
  String get disabled => 'Kapalı';

  @override
  String get speakerNameLabel => 'Konuşmacı adı';

  @override
  String get ready => 'Hazır';

  @override
  String get pending => 'Bekliyor';

  @override
  String get profileReadyForRecognition => 'Profil tanıma için hazır';

  @override
  String get addSampleLater => 'Daha sonra örnek kayıt eklenebilir';

  @override
  String summaryGeneratedAt(Object time) {
    return 'Oluşturulma: $time';
  }
}
