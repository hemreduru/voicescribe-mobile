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
  String get ai => 'AI';

  @override
  String get aiTitle => 'AI Asistan';

  @override
  String get aiSubtitle => 'Kendi kayıtların hakkında soru sor';

  @override
  String get chatNewChat => 'Yeni sohbet';

  @override
  String get chatSources => 'Kaynaklar';

  @override
  String get chatThinking => 'Düşünüyor…';

  @override
  String get chatInputHint => 'Kayıtların hakkında sor…';

  @override
  String get chatSend => 'Gönder';

  @override
  String get chatEmptyTitle => 'Kayıtlarınla sohbet et';

  @override
  String get chatEmptyMessage =>
      'Transkriptlerin hakkında her şeyi sorabilirsin. Yanıtlar, alındıkları kaydı kaynak gösterir.';

  @override
  String get chatNoSessionsTitle => 'Henüz sohbet yok';

  @override
  String get chatNoSessionsMessage =>
      'Tüm kayıtların arasında soru sormak için yeni bir sohbet başlat. Yanıtlar kendi dökümlerinden üretilir.';

  @override
  String get chatNeedsRecordingTitle => 'Önce bir kayıt al';

  @override
  String get chatNeedsRecordingMessage =>
      'Asistan yanıtlarını dökümlerinden üretir. Bir kayıt yap, sonra gelip onun hakkında soru sor.';

  @override
  String get chatSelectOrNew => 'Bir sohbet seç ya da yeni bir sohbet başlat.';

  @override
  String get chatDeleteTitle => 'Sohbeti sil';

  @override
  String get chatDeleteConfirm => 'Bu sohbet kalıcı olarak silinecek.';

  @override
  String get chatUntitled => 'Yeni sohbet';

  @override
  String get refreshFailed =>
      'Yenilenemedi. Bağlantını kontrol edip tekrar dene.';

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
  String get settings => 'Ayarlar';

  @override
  String get openSettings => 'Ayarları aç';

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
  String get aiLocationTitle => 'Yapay zekâ nerede çalışsın?';

  @override
  String get aiLocationLabel => 'Çalışma yeri';

  @override
  String get aiLocationOnDevice => 'Bu telefonda';

  @override
  String get aiLocationCloud => 'Bulutta';

  @override
  String get aiLocationOnDeviceDesc =>
      'Her şey telefonunda çalışır; internet gerekmez ve hiçbir şey cihazdan çıkmaz. Güçlü bir telefon ve tek seferlik ~1 GB model indirme gerekir. Hem özet hem yapay zekâ sohbeti için geçerlidir.';

  @override
  String get aiLocationCloudDesc =>
      'Daha güçlü ve çok daha hızlı yapay zekâ; uzun toplantılarda daha iyi sonuç verir. İnternet ve giriş gerekir, kayıt önce eşitlenir. Hem özet hem yapay zekâ sohbeti için geçerlidir.';

  @override
  String get aiLocationOnDeviceUnavailable =>
      'Bu telefon cihaz içi yapay zekâ için yeterince güçlü değil — bunun yerine Bulut\'u kullanın.';

  @override
  String get autoSummarizeTitle => 'Otomatik özetle';

  @override
  String get autoSummarizeDesc =>
      'Kayıt yazıya döküldüğü anda özet, ekstra dokunuş gerekmeden oluşturulur.';

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get onboardingBack => 'Geri';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingGetStarted => 'Başla';

  @override
  String get onboardingWelcomeTitle => 'VoiceScribe\'a hoş geldin';

  @override
  String get onboardingWelcomeBody =>
      'Her şeyi kaydet; temiz bir döküm ve yapılandırılmış toplantı notları otomatik olarak çıksın.';

  @override
  String get onboardingFeatureRecord => 'Cihazında canlı kayıt ve yazıya dökme';

  @override
  String get onboardingFeatureSummary => 'Otomatik, yapılandırılmış özetler';

  @override
  String get onboardingFeatureChat => 'Kayıtların hakkında soru sor';

  @override
  String get onboardingLanguageTitle => 'Dillerini seç';

  @override
  String get onboardingRecommended => 'Cihazın için önerilen';

  @override
  String get onboardingThemeTitle => 'Bir tema seç';

  @override
  String get onboardingPermissionsTitle => 'Son bir şey';

  @override
  String get onboardingPermissionsBody =>
      'VoiceScribe kayıt için mikrofona, döküm veya özet hazır olduğunda haber vermek için bildirimlere ihtiyaç duyar. Sen istemeden hiçbir şey paylaşılmaz.';

  @override
  String get onboardingAllowAndFinish => 'İzin ver ve başla';

  @override
  String onboardingStepProgress(int current, int total) {
    return 'Adım $current / $total';
  }

  @override
  String get replayIntroTitle => 'Tanıtımı tekrar göster';

  @override
  String get replayIntroSubtitle => 'Karşılama turunu yeniden izle';

  @override
  String get transcribingProgressLabel => 'Yazıya dökülüyor';

  @override
  String get statusHelpRecording => 'Kayıt devam ediyor.';

  @override
  String get statusHelpProcessing => 'Metin şu an hazırlanıyor.';

  @override
  String get statusHelpReady => 'Metin kullanıma hazır.';

  @override
  String get statusHelpIssue => 'Kontrol etmen gerekiyor.';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get summaryPreferences =>
      'Özetlerin ve yapay zekâ sohbetinin nerede çalışacağını seçin.';

  @override
  String get transcriptionModelSettings => 'Transkripsiyon Modeli';

  @override
  String get transcriptionModelPreferences =>
      'Ses transkripsiyonu için cihaz içinde kullanılacak modeli seçin.';

  @override
  String get modelChangeConfirmTitle => 'Model değiştirilsin mi?';

  @override
  String modelChangeConfirmDownload(Object model, Object size) {
    return '$model modeline geçiş için tek seferlik $size indirme gerekir. İndirme arka planda sürer ve hazır olana kadar mevcut model çalışmaya devam eder.';
  }

  @override
  String modelChangeConfirmReady(Object model) {
    return 'Transkripsiyon $model modeline geçirilsin mi?';
  }

  @override
  String get modelChangeConfirmAction => 'Geç';

  @override
  String get modelChangeConfirmDownloadAction => 'İndir ve geç';

  @override
  String get modelChangeBusyTitle => 'Kayıt sürüyor';

  @override
  String get modelChangeBusyMessage =>
      'Transkripsiyon modelini değiştirmeden önce mevcut kaydı tamamlayın — etkin oturum mevcut modeli kullanmaya devam eder.';

  @override
  String get modelApplying => 'Uygulanıyor…';

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
  String summarizingProgress(Object current, Object total) {
    return 'Özetleniyor… ($current/$total)';
  }

  @override
  String get summaryPlaceholder =>
      'Henüz özet yok. Bu transkriptten yapılandırılmış toplantı notları oluşturmak için Özet Oluştur\'a dokun.';

  @override
  String get noSummaryYet => 'Üretilmiş özet henüz yok.';

  @override
  String get summaryUnavailable =>
      'Bu sefer okunabilir bir özet üretilemedi. Tekrar denemek için Özet Oluştur\'a dokun veya Ayarlar\'dan Bulut\'a geç.';

  @override
  String get summaryExecutiveSummary => 'Özet';

  @override
  String get summaryAgenda => 'Gündem';

  @override
  String get summaryDecisions => 'Kararlar';

  @override
  String get summaryActionItems => 'Aksiyon Maddeleri';

  @override
  String get summaryOpenQuestions => 'Açık Konular';

  @override
  String get summaryNotes => 'Notlar';

  @override
  String get summaryAttendees => 'Katılımcılar';

  @override
  String get summaryAbsentees => 'Gelmeyenler';

  @override
  String get summaryRecorder => 'Tutanağı Yazan';

  @override
  String get summaryNextMeeting => 'Sonraki Toplantı';

  @override
  String get summaryProviderLocalLabel => 'Cihazda';

  @override
  String get summaryProviderCloudLabel => 'Bulut';

  @override
  String get summaryUnassigned => 'Atanmadı';

  @override
  String get localSummaryModel => 'Cihaz içi özet modeli';

  @override
  String get localSummaryModelDownload => 'İndir';

  @override
  String get localSummaryModelReady => 'İndirildi';

  @override
  String get localSummaryModelDownloading => 'İndiriliyor…';

  @override
  String get localSummaryModelUnsupported =>
      'Cihaz içi özet için daha güçlü bir cihaz gerekir. Bunun yerine Bulut\'u kullanın.';

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
  String get ok => 'Tamam';

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
  String get logoutConfirmTitle => 'Çıkış yapılsın mı?';

  @override
  String get logoutConfirmMessage =>
      'Eşitleme için yeniden giriş yapmanız gerekir. Bu cihazdaki kayıtlar kullanılabilir kalır.';

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

  @override
  String get retrying => 'Tekrar deneniyor...';

  @override
  String get statusIconsTitle => 'Statü ikonları';

  @override
  String get transcriptionLanguage => 'Transkripsiyon dili';

  @override
  String get transcriptionModelSize => 'Model boyutu';

  @override
  String get recordingNotificationContent => 'Kayıt sürüyor';

  @override
  String get automatic => 'Otomatik';

  @override
  String unsyncedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kayıt henüz yedeklenmedi',
      one: '1 kayıt henüz yedeklenmedi',
    );
    return '$_temp0';
  }

  @override
  String get transcribingNotificationContent => 'Transkript hazırlanıyor';

  @override
  String etaUnitSeconds(int count) {
    return '$count saniye';
  }

  @override
  String etaUnitMinutes(int count) {
    return '$count dakika';
  }

  @override
  String etaUnitHours(int count) {
    return '$count saat';
  }

  @override
  String etaRemaining(String time) {
    return '~$time kaldı';
  }

  @override
  String get errAuthRequired => 'Kayda başlamak için giriş yapın.';

  @override
  String get errMicPermissionRequired => 'Mikrofon izni gerekiyor.';

  @override
  String get errStorageFull =>
      'Depolama dolu. Kayıt durduruldu; yer açıp tekrar deneyin.';

  @override
  String get errSummaryEmptyTranscript => 'Özetlenecek transkript metni yok.';

  @override
  String get errSummaryLocalFailed =>
      'Cihaz üstü model bu sefer geçerli bir özet üretemedi. Lütfen tekrar deneyin veya Bulut özetine geçin.';

  @override
  String get errSummaryTimeout =>
      'Özet beklenenden uzun sürdü. Lütfen tekrar deneyin veya Bulut özetini kullanın.';

  @override
  String get errSummaryNotSynced =>
      'Bu kayıt henüz eşitlenmedi. İnternete bağlanıp eşitledikten sonra bulut özetini tekrar deneyin.';

  @override
  String get errSummaryAuthRequired =>
      'Bulut özeti için giriş yapmış olmanız gerekiyor.';

  @override
  String get errSummaryOffline =>
      'Bağlantı yok. Yerel özete geçin veya çevrimiçi olunca tekrar deneyin.';

  @override
  String get errSummaryServerError =>
      'Özet şu an oluşturulamadı. Lütfen biraz sonra tekrar deneyin.';

  @override
  String get errSummaryInvalidResponse => 'Sunucudan geçersiz yanıt alındı.';

  @override
  String get errSummaryEmptyResponse => 'Sunucu boş bir özet döndürdü.';

  @override
  String get errSummaryGeneric => 'Özet oluşturulamadı. Lütfen tekrar deneyin.';

  @override
  String get errChatEmptyQuestion => 'Lütfen bir soru yazın.';

  @override
  String get errChatTimeout =>
      'Yanıt beklenenden uzun sürdü. Lütfen tekrar deneyin veya Bulut moduna geçin.';

  @override
  String get errChatLocalFailed =>
      'Cihaz üstü yapay zekâ şu an yanıt veremedi. Lütfen tekrar deneyin.';

  @override
  String get errChatEmptyAnswer =>
      'Boş bir yanıt alındı. Lütfen tekrar deneyin.';

  @override
  String get errChatLoadFailed => 'Sohbet yüklenemedi.';

  @override
  String get errChatSendFailed => 'Yanıt alınamadı. Lütfen tekrar dene.';

  @override
  String get errSettingsActionFailed =>
      'Bir şeyler ters gitti. Lütfen tekrar dene.';

  @override
  String get errSettingsSyncFailed =>
      'Eşitleme başarısız. Bağlantını kontrol edip tekrar dene.';

  @override
  String get errSettingsModelDownloadFailed =>
      'Model indirilemedi. Bağlantını kontrol edip tekrar dene.';
}
