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
  String get account => 'Hesap';

  @override
  String get appearance => 'Görünüm';

  @override
  String get theme => 'Tema';

  @override
  String get system => 'Sistem';

  @override
  String get light => 'Açık';

  @override
  String get dark => 'Koyu';

  @override
  String get language => 'Dil';

  @override
  String get english => 'İngilizce';

  @override
  String get turkish => 'Türkçe';

  @override
  String get systemStatus => 'Sistem Durumu';

  @override
  String get summaryProvider => 'Özet Sağlayıcısı';

  @override
  String get summaryLength => 'Özet Uzunluğu';

  @override
  String get summaryPreferences =>
      'Özetlerin nerede çalışacağını ve ne kadar detay içereceğini yönetin.';

  @override
  String get userId => 'Kullanıcı ID';

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
  String get statusTranscriptionCompleted => 'Transkripsiyon tamamlandı';

  @override
  String get statusCompleted => 'Tamamlandı';

  @override
  String get statusTranscriptionError => 'Hata';

  @override
  String get statusEmpty => 'Boş Kayıt';

  @override
  String get statusReady => 'Hazır';

  @override
  String get statusProcessing => 'İşleniyor';

  @override
  String get statusIssue => 'Sorun Var';

  @override
  String get all => 'Tümü';

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
  String get ready => 'Hazır';

  @override
  String get pending => 'Bekliyor';

  @override
  String summaryGeneratedAt(Object time) {
    return 'Oluşturulma: $time';
  }

  @override
  String get authTitle => 'Kimlik Doğrulama';

  @override
  String get login => 'Giriş Yap';

  @override
  String get register => 'Kayıt Ol';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get authenticatedUser => 'Giriş Yapan Kullanıcı';

  @override
  String get authVerifyEmail =>
      'Kayıt tamamlandı. E-posta adresinizi doğrulayıp giriş yapın.';

  @override
  String get modelSetupRequired => 'Model kurulumu gerekli';

  @override
  String get modelSetupContinueMessage =>
      'Devam etmek için model önce indirilmelidir.';

  @override
  String get modelDownloadFailed =>
      'Model indirilemedi. Lütfen tekrar deneyin.';

  @override
  String get modelDownloading => 'Model indiriliyor...';

  @override
  String modelDownloadingPercent(Object percent) {
    return 'Model indiriliyor %$percent';
  }

  @override
  String recordingsCount(Object count) {
    return '$count kayıt';
  }

  @override
  String get deleteRecordingsTitle => 'Kayıtlar silinsin mi?';

  @override
  String deleteRecordingsMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kayıt güvenli şekilde silinecek.',
      one: 'Bu kayıt güvenli şekilde silinecek.',
    );
    return '$_temp0';
  }

  @override
  String chunksCount(Object count) {
    return '$count parça';
  }
}
