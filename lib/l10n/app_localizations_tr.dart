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
  String get sync => 'Senkronizasyon';

  @override
  String get syncSectionSubtitle =>
      'Bekleyen verileri sunucuyla eşitle ve yerel önbelleği temizle.';

  @override
  String get syncNow => 'Şimdi Eşitle';

  @override
  String get syncInProgress => 'Eşitleme sürüyor';

  @override
  String get syncIdle => 'Eşitlemeye hazır';

  @override
  String get lastSyncNever => 'Son eşitleme: Henüz yok';

  @override
  String lastSyncAt(Object time) {
    return 'Son eşitleme: $time';
  }

  @override
  String get syncBannerTitle => 'Eşitleme tamamlandı';

  @override
  String get syncBannerSuccess => 'Her şey güncel.';

  @override
  String syncBannerSuccessWithCounts(
    Object pushed,
    Object pulled,
    Object cleaned,
  ) {
    return '$pushed yüklendi, $pulled yenilendi, $cleaned temizlendi';
  }

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
  String get transcriptionModelSettings => 'Transkripsiyon Modeli';

  @override
  String get transcriptionModelPreferences =>
      'Ses transkripsiyonu için cihaz içinde kullanılacak modeli seçin.';

  @override
  String get recommendedForYourDevice => 'Cihazınız için önerilen';

  @override
  String deviceProfileLabel(Object tier) {
    return 'Cihaz profili: $tier';
  }

  @override
  String get deviceTierEntry => 'Giriş';

  @override
  String get deviceTierBalanced => 'Dengeli';

  @override
  String get deviceTierPerformance => 'Performans';

  @override
  String get deviceTierPremium => 'Üst Seviye';

  @override
  String modelDownloadRemaining(Object size) {
    return 'İndirme: $size';
  }

  @override
  String get modelAlreadyDownloaded => 'Zaten indirildi';

  @override
  String get modelDownloadSizeUnknown => 'İndirme boyutu alınamadı';

  @override
  String get modelCompatibilityRecommended => 'Önerilen';

  @override
  String get modelCompatibilitySupported => 'Uyumlu';

  @override
  String get modelCompatibilityLimited => 'Bu cihazda yavaş olabilir';

  @override
  String get modelApplyingSelection => 'Seçilen model uygulanıyor...';

  @override
  String get modelTinyDescription =>
      'Düşük seviye telefonlar ve hızlı taslaklar için en hızlı seçenek.';

  @override
  String get modelBaseDescription =>
      'Günlük transkripsiyon için dengeli varsayılan.';

  @override
  String get modelSmallDescription =>
      'Orta düzey cihaz maliyetiyle daha iyi doğruluk.';

  @override
  String get modelMediumDescription =>
      'Daha güçlü telefonlar için daha yüksek doğruluk.';

  @override
  String get modelLargeV3Description =>
      'En yüksek genel doğruluk, ancak bellek ve pil kullanımı yüksektir.';

  @override
  String get modelLargeV3TurboDescription =>
      'Daha hızlı işlemle büyük sınıf doğruluğu.';

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

  @override
  String transcriptionProgressPercent(Object percent) {
    return '%$percent';
  }

  @override
  String transcriptionProgressChunks(Object completed, Object total) {
    return '$completed/$total';
  }

  @override
  String recommendedModelLabel(Object model) {
    return 'Önerilen model: $model';
  }

  @override
  String get usingHeavierModelWarning =>
      'Önerilenden daha ağır bir model kullanıyorsunuz. Bu yavaş transkripsiyona neden olabilir.';

  @override
  String get modelWarningHeavy => 'Önerilenden ağır';

  @override
  String get modelWarningSlow => 'Çok yavaş olabilir';

  @override
  String get retryTranscription => 'Tekrar Dene';

  @override
  String get transcriptionFailedRetry =>
      'Transkripsiyon başarısız oldu. Tekrar denemek için dokunun.';
}
