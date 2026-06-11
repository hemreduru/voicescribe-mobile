# VoiceScribe — Kod Tabanı Analizi: Bug & Optimizasyon Planı

> Tarih: 2026-06-11. Kapsam: `lib/` altındaki tüm katmanların (kayıt/transkripsiyon,
> sync/DB, AI özet/sohbet, app iskeleti/auth/UI bloc'ları) satır satır incelemesi.
> `plan/production-readiness.md`'deki release-gate listesinin (imzalama, cleartext,
> crash reporting, token süresi, privacy) **üzerine** kod seviyesinde bulgulardır;
> o liste hâlâ geçerlidir ve P0'dır. Mevcut durum: `flutter analyze` temiz, 117/117
> unit test yeşil.

---

## A. Düzeltilmesi gereken buglar (doğruluk)

### A1. Sync yarış durumu — çift senkron döngüsü ⚠️ Yüksek öncelik
`SyncQueueService._runSync` (`sync_queue_service.dart:193-242`): `_syncInProgress`
bayrağı, token provider + `_hasInternet()` await'lerinden **sonra** set ediliyor.
Debounce timer'ı, 5 dk periyodik timer ve connectivity dinleyicisi aynı anda
tetiklenirse iki `_syncCycle` paralel koşar → aynı satırlar iki kez push edilir,
`_markAnySyncingAsFailed` diğer döngünün satırlarını "failed" işaretler.
**Çözüm:** bayrağı ilk satırda set et (veya tek-uçuş: çalışan döngünün Future'ını
sakla ve ikinci çağrıyı ona bağla).

### A2. Kayıt durdurma sırasında flush hatası UI'yı kilitler
`AudioRecordingService.stop()` (`audio_recording_service.dart:148-162`): kayıt
sırasındaki chunk yazımları `catchError` ile korunuyor ama `finish()` flush'ı
korunmasız `await _emitChunk(chunk)`. Durdurma anında disk dolarsa `stop()` fırlatır →
`RecordingBloc._onStopped` `isRecording:false` emit edemeden patlar → UI sonsuza
kadar "kayıtta" kalır (timer durmuş, buton kilitli).
**Çözüm:** finish-flush'ı try/catch'e al; hata olsa da oturumu finalize et ve
`RecordingStorageException` mesajını göster.

### A3. Açılıştaki orphan temizliği taze kayıt dosyasını silebilir
`BootstrapBloc._cleanupOrphanChunkFiles` (`bootstrap_bloc.dart:202,215-247`):
`knownPaths`, bootstrap **başında** alınan snapshot'tan kuruluyor; temizlik ise
app "ready" olduktan sonra unawaited koşuyor. Kullanıcı hemen kayda başlarsa yeni
yazılan WAV'lar snapshot'ta yok → "orphan" sanılıp silinebilir (chunk transkripsiyonu
kaybolur).
**Çözüm:** silmeden önce dosya mtime'ı bootstrap zamanından yeniyse atla (en basit)
veya snapshot'ı silme anında tazele.

### A4. `currentTranscript` durdurma sonrası temizlenmiyor + retry eski kaydı "aktif" yapıyor
`RecordingBloc`: `_onStopped` `currentTranscript`'i durmuş kayıtta bırakıyor;
`_stateForSnapshot` (`recording_bloc.dart:797-847`) bu "aktif oturumu" sonsuza dek
koruyor — kullanıcı o kaydı listeden silse bile snapshot merge'i onu state'e geri
ekler (hayalet kayıt). Ayrıca `_onChunkRetryRequested` (`:516-562`) retry edilen
eski transkripti `currentTranscript` yapıyor; o sırada yeni kayıt başlatılırsa
progress/ETA hesapları yanlış sete bakar.
**Çözüm:** transkripsiyon kuyruğu boşalınca (veya en geç stop'ta status final
olduğunda) `currentTranscript`'i null'a çek; retry akışında `currentTranscript`'e
yazma, sadece `transcripts` listesinde güncelle.

### A5. `as Exception` cast'i gerçek hatayı maskeliyor
`WhisperTranscriptionService._executeWithRetry` (`whisper_service.dart:424`):
`lastError = error as Exception` — plugin bir `Error` (OOM, StateError) fırlatırsa
cast `TypeError` üretir, asıl hata kaybolur.
**Çözüm:** `Object? lastError` + `Error.throwWithStackTrace`.

### A6. Kullanıcıya görünen hata metinleri l10n dışı ve dil-karışık
- `RecordingBloc._userMessageFor` + auth akışı: **İngilizce** hardcoded
  ("Microphone permission is required.").
- `LocalSummaryException`, `CloudSummaryException`, `LocalChatException`,
  `ChatCubit`: **Türkçe** hardcoded.
İngilizce telefonda Türkçe hata, Türkçe telefonda İngilizce hata görünür; mevcut
`l10n` altyapısı (en/tr ARB'ler) tamamen bypass edilmiş.
**Çözüm:** servisler hata **kodu** taşısın (enum/sealed), UI katmanı `context.l10n`
ile çevirsin. (Mevcut `SummaryFailure.message` deseni koda dönüştürülecek.)

### A7. SQLite foreign key'ler etkisiz
`database_provider.dart` şemada `ON DELETE CASCADE` tanımlı ama sqflite'ta
`PRAGMA foreign_keys = ON` hiç açılmıyor → cascade hiçbir zaman çalışmaz. Bugün
soft-delete kullanıldığı için maskeli; ileride hard-delete eklenirse sessiz veri
tutarsızlığı.
**Çözüm:** `onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON')` ya da
şemadan FK iddiasını kaldır (tercih: pragma'yı aç).

### A8. Lokal sohbette bağlam taşması riski
`LocalChatService`: 3 kaynak × 1500 karakter + 6 mesaj geçmiş + soru,
`LocalLlmRuntime.generate(maxTokens: 2048)` penceresine (giriş+çıkış dahil)
sığmayabilir; Türkçe'de ~4500+ karakter ≈ 2000+ token → cevap kırpılır/boşalır.
**Çözüm:** kaynak bütçesini ~900 karaktere indir veya `maxTokens`'ı yükselt
(cihaz matrisinde doğrulayarak); toplam giriş karakterini tek yerden bütçele.

---

## B. Performans / ölçeklenebilirlik optimizasyonları

### B1. Snapshot mimarisi: her yazım tüm DB'yi yeniden okuyor 🔥 En büyük kaldıraç
`SqfliteTranscriptRepository._emitSnapshot()` her `saveChunk`/`saveTranscript`/
`saveSummary`'de **tüm** transcripts+chunks+summaries tablolarını okuyup tüm
dinleyicilere yayınlıyor. Kayıt sırasında her 15 sn'lik chunk başına ~4 tam-DB
okuması; `TranscriptListBloc._buildItems` her snapshot'ta ve **her arama tuşunda**
bütün kayıtların tüm metnini yeniden birleştiriyor (`transcript_list_bloc.dart:323-371`).
Aylarca kullanımda (binlerce chunk) kayıt ekranı ve liste donmaya başlar.
**Plan (kademeli):**
1. Snapshot emisyonlarını coalesce et (microtask/50 ms debounce) — ucuz, hemen.
2. Arama girdisine 250 ms debounce + birleşik metni `transcript.updatedAt` anahtarlı
   cache'le.
3. Orta vade: `watchSnapshot`'ı parçala — liste için transcripts-only sorgu +
   chunk sayıları (GROUP BY), detay için transcript-başına chunk sorgusu.

### B2. SQLite index yok
Şemada tek bir index yok. Sync merge'i pulled satır başına `remoteId`/`localId`
sorgusu atıyor (N+1 full scan), `transcriptId` filtreleri ve `syncStatus`
taramaları da öyle.
**Çözüm (DB v8 migrasyonu):**
`transcript_chunks(transcriptId)`, `transcript_chunks(syncStatus)`,
`transcript_chunks(remoteId)`, `transcripts(remoteId)`, `transcripts(localId)`,
`transcripts(syncStatus)`, `summaries(transcriptId)`, `summaries(syncStatus)`.

### B3. `PcmChunker._countSilentSamples` O(n²) bellek fırtınası
`pcm_chunker.dart:196-205`: döngünün **her örneğinde** `Uint8List.fromList(data)`
ile tüm tail kopyalanıyor — 1 sn overlap için 16.000 iterasyon × 32 KB ≈ **0.5 GB**
geçici tahsis, her chunk kapanışında. GC baskısı = kayıt sırasında jank.
**Çözüm:** dönüşümü döngü dışına al (tek `Uint8List.fromList`). Bonus:
`levelFor`/`_averageLevelFor` kopyaları tekilleştir; `_buffer`'ı `List<int>` yerine
`BytesBuilder` yap (bayt başına 8 kat bellek tasarrufu).

### B4. Açılış ağa bloke
- `BootstrapBloc._bootstrap` (`bootstrap_bloc.dart:189`) "ready" demeden önce
  `refresh()` → tam GET /transcripts (20 sn timeout'a kadar) bekliyor.
- `AuthBloc._onStarted` → `_syncQueueService.start()` ilk tam sync döngüsünü
  await ediyor.
Yavaş ağda soğuk açılış saniyelerce uzar.
**Çözüm:** her ikisini de `unawaited(...)` yap; UI lokal cache ile anında açılsın
(offline-first vaadinin gereği).

### B5. Sync başına çift ağ turu
Her sync döngüsü zaten pull yapıyor; ardından `onSyncComplete:
_transcriptRepository.refresh` **bir kez daha** tam GET /transcripts çekiyor —
5 dk'da bir gereksiz tam liste indirme.
**Çözüm:** `onSyncComplete`'i sadece `_emitSnapshot`'a indir (sunucu verisi pull
ile zaten geldi); tam fetch yalnızca login/ilk açılışta kalsın.

### B6. Whisper model indirme: resume yok, stall timeout yok
`_downloadModel` (`whisper_service.dart:544-608`): bağlantı koparsa `.part`
siliniyor → 466 MB `small` modeli baştan iner; stream'de per-chunk timeout yok →
takılı bağlantı bootstrap'ı sonsuza dek asar; progress her ağ paketinde emit
ediliyor (binlerce event).
**Çözüm:** HTTP `Range` ile devam et, chunk-arası ~30 sn timeout, progress'i %1
değişimde yayınla.

### B7. Lokal LLM her çağrıda model açıp kapatıyor
`LocalLlmRuntime.generate` her inferansta `getActiveModel` + `model.close()`.
Map-reduce'lu uzun özette 7+ kez model yükleme/kapatma — pencere başına saniyeler.
**Çözüm:** özet/sohbet oturumu boyunca modeli açık tut (servis seviyesinde yaşam
döngüsü); cihazda stabilite sweep'i ile doğrula (Gemma GPU kararsızlığı geçmişi var).

### B8. Sınırsız push batch + dar HTTP timeout
`_buildPushBatch` tüm pending/failed satırları tek istekte gönderiyor; gövde
yükleme penceresi 15 sn (`sync_http_client.dart:41`). Uzun offline birikimi yavaş
ağda hep timeout'a düşer → sync hiç ilerleyemez.
**Çözüm:** push'u ~200 satırlık dilimlere böl (dilim başına commit), timeout'u
gövde boyutuna oranla ölçekle.

### B9. Küçük temizlikler
- `_cleanupChunkAudioFiles` sync IO (`existsSync/deleteSync`) — async'e çevir.
- `AudioRecordingService._emitChunk` her chunk'ta `getApplicationDocumentsDirectory()`
  çağırıyor — start'ta bir kez çözüp sakla.
- `TranscriptApiClient` her istekte yeni `HttpClient` — paylaşılan client ile
  keep-alive.
- Circuit breaker (`_circuitBreakerThreshold`) fiilen ölü: retry `scheduleSync`
  → `force: true` ile breaker'ı her zaman bypass ediyor — niyeti netleştir
  (retry'lar force olmasın).

---

## C. Üretim kapıları (production-readiness.md ile hizalı, hâlâ açık)

Bunlar dokümanda zaten P0/P1; bu analiz doğruladı, ek not düşülenler:

1. **Release imzalama** debug keystore'da (`build.gradle` TODO) — P0.
2. **`usesCleartextTraffic="true"`** global — P0; HTTPS + scoped
   `network_security_config`.
3. **EnvConfig default'ları dev ortamına işaret ediyor** (`http://vsbackend.test`,
   `192.168.8.20` LAN rewrite): release build `API_BASE_URL` dart-define'ı
   unutulursa app sessizce LAN'a bağlanmaya çalışır. **Ek öneri:** release modda
   (`kReleaseMode`) base URL dev host'larından biriyse açılışta fail-fast/assert.
4. **Crash reporting yok** (Talker lokal) — Sentry/Crashlytics P1.
5. **Token süresiz + 401 akışı yok** — `isUnauthorized` zaten mevcut; sync 401
   aldığında oturumu düşürüp login'e yönlendiren tek bir nokta ekle (şu an 401,
   genel "failed" gibi sonsuz retry'a girer).
6. Privacy policy + Play data-safety formu (mikrofon/ses) — P1.

---

## D. Uygulama sırası (önerilen sprint planı)

| Faz | İçerik | Boyut |
|---|---|---|
| **Faz 0 — Release kapıları** | C1–C3 (imzalama, cleartext/HTTPS, env fail-fast) + C4 Sentry | 1-2 gün |
| **Faz 1 — Doğruluk** | A1 (sync race), A2 (stop flush), A3 (orphan race), A5 (cast), A7 (FK pragma) + birim testleri | 1-2 gün |
| **Faz 2 — Perf hızlı kazanımlar** | B2 (indexler), B3 (chunker O(n²)), B1.1-1.2 (coalesce + arama debounce/cache), B4 (açılış unawaited), B5 (çift fetch) | 2-3 gün |
| **Faz 3 — Sağlamlaştırma** | A4 (currentTranscript), B6 (download resume), B8 (push batching), C5 (401 akışı) | 2-3 gün |
| **Faz 4 — Kalite/i18n** | A6 (hata kodları → l10n), A8 (chat bütçesi), B7 (LLM oturumu, cihaz doğrulamalı), B9 | 2-3 gün |

Her faz sonunda: `flutter analyze` + `flutter test` (117 baz) + gerçek cihazda
kayıt→transkript→özet→sync dumanı testi (emülatör mikrofonu çalışmıyor —
gerçek cihaz şart).
