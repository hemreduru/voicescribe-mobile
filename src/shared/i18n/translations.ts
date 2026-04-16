/**
 * Internationalization translations for VoiceScribe Mobile.
 * Supports Turkish (tr) and English (en).
 */

export type Locale = 'tr' | 'en';

export interface Translations {
  // Tab labels
  tabRecording: string;
  tabTranscript: string;
  tabSummary: string;
  tabHistory: string;
  tabSpeaker: string;

  // Recording Screen
  recording: string;
  recordingPaused: string;
  isRecording: string;
  tapToRecord: string;
  sessionNamePlaceholder: string;
  recentRecordings: string;
  viewAll: string;
  noRecordings: string;
  aiReady: string;
  modelLoading: string;
  pause: string;
  resume: string;
  stop: string;

  // Transcript Screen
  transcript: string;
  searchRecordings: string;
  copy: string;
  export: string;
  edit: string;
  noTranscript: string;
  transcriptEmptyDesc: string;
  searchInText: string;
  noMatchingText: string;
  noTranscriptAvailable: string;
  transcribing: string;
  transcriptionError: string;
  emptySession: string;
  noTextGenerated: string;

  // Statuses
  status_recording: string;
  status_transcribing: string;
  status_completed: string;
  status_transcription_error: string;
  status_empty: string;

  // Summary Screen
  summary: string;
  local: string;
  cloud: string;
  short: string;
  medium: string;
  long: string;
  regenerate: string;
  aiSummary: string;
  provider: string;
  length: string;
  noTranscriptSelected: string;
  summaryEmptyDesc: string;
  generateSummary: string;
  aiGeneratingSummary: string;
  localAI: string;
  cloudAI: string;

  // History Screen
  history: string;
  searchInRecordings: string;
  delete: string;
  newest: string;
  oldest: string;
  longest: string;
  selectAll: string;
  deselectAll: string;
  deleteRecordings: string;
  deleteConfirmMessage: string;
  cancel: string;
  noRecordingsFound: string;
  noSearchResults: string;
  noRecordingsYet: string;
  synced: string;

  // Speaker Screen
  speaker: string;
  speakerRecognition: string;
  speakerRecognitionDesc: string;
  addNewSpeaker: string;
  registeredSpeakers: string;
  voiceSampleAvailable: string;
  recordVoiceSample: string;
  listen: string;
  voiceSample: string;
  speakerMatchHistory: string;
  matchesInLast30: string;
  successfulMatch: string;
  noSpeakers: string;
  noSpeakersDesc: string;
  deleteSpeaker: string;
  deleteSpeakerConfirm: string;
  editSpeaker: string;
  speakerName: string;
  update: string;
  add: string;
  enterName: string;
  error: string;
  info: string;
  voiceRecordInfo: string;

  // Settings Screen
  settings: string;
  profile: string;
  logout: string;
  deleteAccount: string;
  transcription: string;
  language: string;
  model: string;
  autoTranscription: string;
  autoTranscriptionDesc: string;
  summarization: string;
  localSummary: string;
  localSummaryDesc: string;
  cloudSummary: string;
  cloudSummaryDesc: string;
  defaultSummaryLength: string;
  llmProvider: string;
  sync: string;
  autoSync: string;
  autoSyncDesc: string;
  manualSync: string;
  lastSync: string;
  storage: string;
  usedStorage: string;
  clearCache: string;
  exportData: string;
  app: string;
  theme: string;
  themeLight: string;
  themeDark: string;
  themeSystem: string;
  selectTheme: string;
  notifications: string;
  version: string;
  about: string;
  privacyPolicy: string;
  termsOfUse: string;
  helpSupport: string;
  appLanguage: string;

  // Bootstrap
  bootstrapTitle: string;
  bootstrapMessage: string;
  bootstrapFailed: string;
  retrySetup: string;
  downloadingModel: string;
  modelDownloaded: string;

  // Common
  permissionDenied: string;
  micPermissionRequired: string;
  askLater: string;
  ok: string;
  micPermissionTitle: string;
  micPermissionMessage: string;
  unnamed: string;
}

export const tr: Translations = {
  // Tab labels
  tabRecording: 'Kayıt',
  tabTranscript: 'Transkript',
  tabSummary: 'Özet',
  tabHistory: 'Geçmiş',
  tabSpeaker: 'Konuşmacı',

  // Recording Screen
  recording: 'Kayıt',
  recordingPaused: 'Kayıt duraklatıldı',
  isRecording: 'Kaydediliyor',
  tapToRecord: 'Kayıt başlatmak için butona tıklayın',
  sessionNamePlaceholder: 'Oturum adı girin...',
  recentRecordings: 'Son Kayıtlar',
  viewAll: 'Tümünü Gör',
  noRecordings: 'Henüz kayıt bulunmuyor',
  aiReady: 'AI Hazır',
  modelLoading: 'Model yükleniyor...',
  pause: 'Duraklat',
  resume: 'Devam Et',
  stop: 'Durdur',

  // Transcript Screen
  transcript: 'Transkript',
  searchRecordings: 'Kayıtlarda ara...',
  copy: 'Kopyala',
  export: 'Dışa Aktar',
  edit: 'Düzenle',
  noTranscript: 'Transkript',
  transcriptEmptyDesc: 'Ses kayıtlarınız burada görünecek.',
  searchInText: 'Metinde ara...',
  noMatchingText: 'Eşleşen metin bulunamadı.',
  noTranscriptAvailable: 'Transkript mevcut değil.',
  transcribing: 'Transkripsiyon devam ediyor... Lütfen bekleyin.',
  transcriptionError: 'Bu oturum için transkripsiyon başarısız.',
  emptySession: 'Bu oturumda konuşma algılanmadı.',
  noTextGenerated: 'Henüz transkript oluşturulmadı.',

  // Statuses
  status_recording: 'Kaydediliyor',
  status_transcribing: 'Çevriliyor',
  status_completed: 'Tamamlandı',
  status_transcription_error: 'Hata',
  status_empty: 'Boş Kayıt',

  // Summary Screen
  summary: 'Özet',
  local: 'Yerel',
  cloud: 'Bulut',
  short: 'Kısa',
  medium: 'Orta',
  long: 'Uzun',
  regenerate: 'Yeniden Oluştur',
  aiSummary: 'AI Özeti',
  provider: 'Sağlayıcı',
  length: 'Uzunluk',
  noTranscriptSelected: 'Transkript seçilmedi',
  summaryEmptyDesc: 'AI özeti oluşturmak için bir oturum seçin.',
  generateSummary: 'Özet Oluştur',
  aiGeneratingSummary: 'AI özet oluşturuyor...',
  localAI: 'Yerel AI',
  cloudAI: 'Cloud AI',

  // History Screen
  history: 'Geçmiş',
  searchInRecordings: 'Kayıtlarda ara...',
  delete: 'Sil',
  newest: 'En Yeni',
  oldest: 'En Eski',
  longest: 'En Uzun',
  selectAll: 'Tümünü Seç',
  deselectAll: 'Tümünü Seçimi Kaldır',
  deleteRecordings: 'Kayıtları Sil',
  deleteConfirmMessage: 'kaydı silmek istediğinize emin misiniz?',
  cancel: 'İptal',
  noRecordingsFound: 'Kayıt Bulunamadı',
  noSearchResults: 'Arama kriterlerinize uygun kayıt yok.',
  noRecordingsYet: 'Henüz hiç kayıtınız yok.',
  synced: 'Senkron',

  // Speaker Screen
  speaker: 'Konuşmacı',
  speakerRecognition: 'Konuşmacı Tanıma',
  speakerRecognitionDesc: 'Kayıtlardaki konuşmacıları otomatik olarak tanımla ve etiketle',
  addNewSpeaker: 'Yeni Konuşmacı Ekle',
  registeredSpeakers: 'Kayıtlı Konuşmacılar',
  voiceSampleAvailable: 'Ses örneği mevcut',
  recordVoiceSample: 'Ses örneği kaydet',
  listen: 'Dinle',
  voiceSample: 'Ses Örneği',
  speakerMatchHistory: 'Konuşmacı Eşleşme Geçmişi',
  matchesInLast30: 'Son 30 kayıtta 156 konuşmacı eşleşmesi yapıldı',
  successfulMatch: 'Başarılı eşleşme',
  noSpeakers: 'Hiç Konuşmacı Yok',
  noSpeakersDesc: 'Konuşmacı tanımayı kullanabilmek için ilk konuşmacınızı ekleyin.',
  deleteSpeaker: 'Konuşmacıyı Sil',
  deleteSpeakerConfirm: 'Bu konuşmacıyı silmek istediğinize emin misiniz?',
  editSpeaker: 'Konuşmacıyı Düzenle',
  speakerName: 'Konuşmacı adı',
  update: 'Güncelle',
  add: 'Ekle',
  enterName: 'Lütfen bir isim girin',
  error: 'Hata',
  info: 'Bilgi',
  voiceRecordInfo: 'Ses örneği kaydı yapılacak',

  // Settings Screen
  settings: 'Ayarlar',
  profile: 'Profil',
  logout: 'Çıkış Yap',
  deleteAccount: 'Hesabı Sil',
  transcription: 'Transkripsiyon',
  language: 'Dil',
  model: 'Model',
  autoTranscription: 'Otomatik Transkripsiyon',
  autoTranscriptionDesc: 'Kayıt sonrası otomatik başlat',
  summarization: 'Özetleme',
  localSummary: 'Yerel Özet',
  localSummaryDesc: 'Cihazda AI ile oluştur',
  cloudSummary: 'Cloud Özet',
  cloudSummaryDesc: 'Bulut AI ile oluştur',
  defaultSummaryLength: 'Varsayılan Özet Uzunluğu',
  llmProvider: 'LLM Provider',
  sync: 'Senkronizasyon',
  autoSync: 'Otomatik Sync',
  autoSyncDesc: 'Kayıtları otomatik senkronize et',
  manualSync: 'Manuel Sync',
  lastSync: 'Son sync: 2 saat önce',
  storage: 'Depolama',
  usedStorage: 'Kullanılan Depolama',
  clearCache: 'Önbelleği Temizle',
  exportData: 'Verileri Dışa Aktar',
  app: 'Uygulama',
  theme: 'Tema',
  themeLight: 'Açık',
  themeDark: 'Koyu',
  themeSystem: 'Sistem',
  selectTheme: 'Tema Seçin',
  notifications: 'Bildirimler',
  version: 'Versiyon',
  about: 'Hakkında',
  privacyPolicy: 'Gizlilik Politikası',
  termsOfUse: 'Kullanım Koşulları',
  helpSupport: 'Yardım & Destek',
  appLanguage: 'Uygulama Dili',

  // Bootstrap
  bootstrapTitle: 'VoiceScribe Kurulumu',
  bootstrapMessage: 'Konuşma modeli hazırlanıyor. İlk açılış biraz zaman alabilir.',
  bootstrapFailed: 'VoiceScribe, konuşma modeli hazır olana kadar devam edemiyor.',
  retrySetup: 'Tekrar Dene',
  downloadingModel: 'Konuşma modeli indiriliyor...',
  modelDownloaded: 'Model indirildi. Kurulum tamamlanıyor...',

  // Common
  permissionDenied: 'İzin Reddedildi',
  micPermissionRequired: 'Mikrofon izni gerekli.',
  askLater: 'Sonra Sor',
  ok: 'Tamam',
  micPermissionTitle: 'Mikrofon İzni',
  micPermissionMessage: 'VoiceScribe, kayıt ve transkripsiyon için mikrofon erişimine ihtiyaç duyar.',
  unnamed: 'Adsız Kayıt',
};

export const en: Translations = {
  // Tab labels
  tabRecording: 'Record',
  tabTranscript: 'Transcript',
  tabSummary: 'Summary',
  tabHistory: 'History',
  tabSpeaker: 'Speakers',

  // Recording Screen
  recording: 'Record',
  recordingPaused: 'Recording paused',
  isRecording: 'Recording',
  tapToRecord: 'Tap the button to start recording',
  sessionNamePlaceholder: 'Enter session name...',
  recentRecordings: 'Recent Recordings',
  viewAll: 'View All',
  noRecordings: 'No recordings yet',
  aiReady: 'AI Ready',
  modelLoading: 'Loading model...',
  pause: 'Pause',
  resume: 'Resume',
  stop: 'Stop',

  // Transcript Screen
  transcript: 'Transcript',
  searchRecordings: 'Search recordings...',
  copy: 'Copy',
  export: 'Export',
  edit: 'Edit',
  noTranscript: 'Transcript',
  transcriptEmptyDesc: 'Your audio archives will appear here.',
  searchInText: 'Search in text...',
  noMatchingText: 'No matching text found.',
  noTranscriptAvailable: 'No transcript available.',
  transcribing: 'Transcription in progress... Please wait.',
  transcriptionError: 'Transcription failed for this session.',
  emptySession: 'No speech was captured in this session.',
  noTextGenerated: 'No transcript text generated yet.',

  // Statuses
  status_recording: 'Recording',
  status_transcribing: 'Transcribing',
  status_completed: 'Completed',
  status_transcription_error: 'Error',
  status_empty: 'Empty',

  // Summary Screen
  summary: 'Summary',
  local: 'Local',
  cloud: 'Cloud',
  short: 'Short',
  medium: 'Medium',
  long: 'Long',
  regenerate: 'Regenerate',
  aiSummary: 'AI Summary',
  provider: 'Provider',
  length: 'Length',
  noTranscriptSelected: 'No transcript selected',
  summaryEmptyDesc: 'Select a session to generate an AI summary.',
  generateSummary: 'Generate Summary',
  aiGeneratingSummary: 'AI is generating summary...',
  localAI: 'Local AI',
  cloudAI: 'Cloud AI',

  // History Screen
  history: 'History',
  searchInRecordings: 'Search recordings...',
  delete: 'Delete',
  newest: 'Newest',
  oldest: 'Oldest',
  longest: 'Longest',
  selectAll: 'Select All',
  deselectAll: 'Deselect All',
  deleteRecordings: 'Delete Recordings',
  deleteConfirmMessage: 'Are you sure you want to delete these recordings?',
  cancel: 'Cancel',
  noRecordingsFound: 'No Recordings Found',
  noSearchResults: 'No recordings match your search.',
  noRecordingsYet: 'No recordings yet.',
  synced: 'Synced',

  // Speaker Screen
  speaker: 'Speakers',
  speakerRecognition: 'Speaker Recognition',
  speakerRecognitionDesc: 'Automatically identify and label speakers in recordings',
  addNewSpeaker: 'Add New Speaker',
  registeredSpeakers: 'Registered Speakers',
  voiceSampleAvailable: 'Voice sample available',
  recordVoiceSample: 'Record voice sample',
  listen: 'Listen',
  voiceSample: 'Voice Sample',
  speakerMatchHistory: 'Speaker Match History',
  matchesInLast30: '156 speaker matches in the last 30 recordings',
  successfulMatch: 'Successful matches',
  noSpeakers: 'No Speakers',
  noSpeakersDesc: 'Add your first speaker to use speaker recognition.',
  deleteSpeaker: 'Delete Speaker',
  deleteSpeakerConfirm: 'Are you sure you want to delete this speaker?',
  editSpeaker: 'Edit Speaker',
  speakerName: 'Speaker name',
  update: 'Update',
  add: 'Add',
  enterName: 'Please enter a name',
  error: 'Error',
  info: 'Info',
  voiceRecordInfo: 'Voice sample will be recorded',

  // Settings Screen
  settings: 'Settings',
  profile: 'Profile',
  logout: 'Log Out',
  deleteAccount: 'Delete Account',
  transcription: 'Transcription',
  language: 'Language',
  model: 'Model',
  autoTranscription: 'Auto Transcription',
  autoTranscriptionDesc: 'Start automatically after recording',
  summarization: 'Summarization',
  localSummary: 'Local Summary',
  localSummaryDesc: 'Generate with on-device AI',
  cloudSummary: 'Cloud Summary',
  cloudSummaryDesc: 'Generate with cloud AI',
  defaultSummaryLength: 'Default Summary Length',
  llmProvider: 'LLM Provider',
  sync: 'Sync',
  autoSync: 'Auto Sync',
  autoSyncDesc: 'Automatically sync recordings',
  manualSync: 'Manual Sync',
  lastSync: 'Last sync: 2 hours ago',
  storage: 'Storage',
  usedStorage: 'Used Storage',
  clearCache: 'Clear Cache',
  exportData: 'Export Data',
  app: 'App',
  theme: 'Theme',
  themeLight: 'Light',
  themeDark: 'Dark',
  themeSystem: 'System',
  selectTheme: 'Select Theme',
  notifications: 'Notifications',
  version: 'Version',
  about: 'About',
  privacyPolicy: 'Privacy Policy',
  termsOfUse: 'Terms of Use',
  helpSupport: 'Help & Support',
  appLanguage: 'App Language',

  // Bootstrap
  bootstrapTitle: 'VoiceScribe Setup',
  bootstrapMessage: 'Preparing the speech model. First launch can take a while.',
  bootstrapFailed: 'VoiceScribe cannot continue until the speech model is ready.',
  retrySetup: 'Retry Setup',
  downloadingModel: 'Downloading speech model...',
  modelDownloaded: 'Model downloaded. Finalizing setup...',

  // Common
  permissionDenied: 'Permission Denied',
  micPermissionRequired: 'Microphone permission is required.',
  askLater: 'Ask Later',
  ok: 'OK',
  micPermissionTitle: 'Microphone Permission',
  micPermissionMessage: 'VoiceScribe needs microphone access to record and transcribe.',
  unnamed: 'Unnamed Recording',
};

const translations: Record<Locale, Translations> = { tr, en };

export function getTranslations(locale: Locale): Translations {
  return translations[locale];
}
