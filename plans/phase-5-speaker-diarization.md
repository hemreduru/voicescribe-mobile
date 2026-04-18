# Phase 5 — On-device Speaker Diarization & Persistent Speaker Profiles

## Amaç
- Canlı veya kayıt sırasında konuşmacıları otomatik olarak ayrıştırmak (diarization) ve her konuşmacıya tekil etiket atamak (Voice-1, Voice-2, ...).
- Kullanıcı bir konuşmacıya bir isim verdiğinde (ör. "Hurşit"), bu konuşmacı daha sonra farklı session'larda yeniden tanınsın ve transcriptlerde aynı isim gösterilsin.
- UI: `Speaker` ekranında konuşmacı listesi, isimlendirme ve ilgili transcript başlıklarına erişim; `Transcript` ekranında her segmentin konuşmacı etiketi görünsün.
- Kısıtlar: manuel enrollment, ses örneği kaydetme veya açık enrollment akışları yok. Konuşmacı tanıma her zaman açık olacak.

## Mimari Özet
- Native katman (Android/iOS) — on-device embedding çıkarımı ve kısa süreli diarization pipeline. Android için Kotlin + JNI + C++ (veya mevcut whisper altyapısına paralel native modül). iOS için Objective-C/Swift + ObjC++ bridge (ayrıntılar ileride).
- JS/TS katmanı — UI, persistent store erişimi, native bridge çağrıları. React Native tarafında `src/native/speaker/NativeSpeakerModule.ts` köprüsü kullanılacak.
- Persistans — SQLite (SQLCipher önerisi opsiyonel, Phase 13'te ele alınacak). Speaker profile tablosu: id, persistent_embedding (float32[] blob), display_name, created_at, last_seen_at, fingerprint_hash.

## Veri Modeli (SQLite)
- Table `speakers`:
  - `id` INTEGER PRIMARY KEY AUTOINCREMENT
  - `label` TEXT NOT NULL DEFAULT ''   -- örn: "Voice-1" başlangıçta
  - `display_name` TEXT NULL         -- kullanıcı tarafından atanmış isim (ör. "Hurşit")
  - `embedding` BLOB NOT NULL        -- float32 array (serialized)
  - `fingerprint` TEXT NOT NULL     -- embedding'in kısa hash'i (örn. SHA256(base64(embedding_slice)))
  - `last_seen_at` INTEGER          -- epoch millis

- Table `sessions` (varsa): metadata için session id, timestamps ve ilişkilendirme yapılabilir.

## İş Akışı (Runtime)
1. Ses parçalama (chunking) zaten mevcut: her audio chunk için VAD ile segment oluşturuluyor. (Mevcut `NativeAudioModule` event: `onAudioChunkReady`).
2. Her segment için native taraf embedding çıkarılır (lightweight speaker embedder — ECAPA-TDNN tiny veya benzeri). Bu işlem native C++ veya NDK ile yapılır.
3. Embedding alındıktan sonra: JS tarafına `speakerEmbeddingAvailable` event'i gönderilir (payload: base64(embedding), segmentStart, segmentEnd, tempLabelID).
4. JS tarafında embedding, mevcut `speakers` tablosuyla karşılaştırılır:
   - Her kayıt için cosine similarity hesaplanır (embedding normalize edilmiş olmalı).
   - Eğer en yüksek similarity > MATCH_THRESHOLD (ör. öneri: 0.75) ise aynı konuşmacı kabul edilir — matched speaker id döner.
   - Eğer eşleşme yoksa yeni temporary speaker oluşturulur: `label` = `Voice-N` (N incremental), embedding kaydedilir.
5. Temporary speakerlar session boyunca kullanılacak; eğer bir temp speaker bir süre içinde yeterli sayıda eşleşme (ör. >= 3 seg) alırsa kalıcıya dönüştürülür.
6. Kullanıcı `Speaker` ekranından `Voice-N`'e tıklayıp `display_name` atadığında, `speakers.display_name` güncellenir — bu değişiklik tüm transcriptler ve UI'larda yansıtılır.
7. Uzun vadede tekrarlı eşleştirme: yeni bir kayıt session'ında çıkan embedding, önce `speakers` tablosuyla eşleştirilir; eşleşirse o `display_name` kullanılır.

## Native Module API (taslak)
- Android Kotlin native module: `NativeSpeakerEngine` (benzer pattern ile `WhisperEngine` oluşturulmalı)
  - `initSpeakerEngine()` -> boolean
  - `extractEmbeddingFromFile(filePath: String): Promise<string(base64Embedding)>`
  - `extractEmbeddingFromFloatArray(floatArray: Float32Array): Promise<string>`
  - `freeSpeakerEngine()`
  - Event: `onSpeakerEmbedding` -> { embeddingBase64, startMs, endMs, tempId }

- JS bridge: `NativeSpeakerModule` (TS) expose eder:
  - `isSpeakerEngineReady(): Promise<boolean>`
  - `ensureSpeakerEngine(modelPath: string): Promise<void>`
  - `requestEmbeddingFromChunk(chunkPath: string): Promise<string>`
  - Event listener registration for `onSpeakerEmbedding` and errors

## Algoritma Detayları
- Embedding modeli: ECAPA-TDNN small/tiny veya daha hafif alternatif (192 dim). Model quantize edilebilir.
- Embedding normalization: L2 normalize.
- Similarity: Cosine similarity; `similarity = dot(a,b)` çünkü vektörler normalize.
- Matching strategy:
  - İlk olarak `fingerprint` (kısa hash) ile cheap ön-eleme yap
  - Ardından cosine similarity hesapla
  - Eşikler: `MATCH_THRESHOLD = 0.75`, `ENROLL_THRESHOLD = 0.85` (eğer similarity yüksekse doğrudan maple)
- Speaker clustering (session içi): temporary cluster oluştur — her cluster için centroid maintain et.
- Drift handling: zamanla profile embedding'leri güncelle (moving-average veya son N embedding'i replace et) — opsiyonel olarak `last_seen_at` güncellendiğinde hafif güncelleme yap.

## UI Entegrasyonu
- `SpeakerScreen` (`src/features/speaker/presentation/screens/SpeakerScreen.tsx`):
  - Liste: label (`Voice-1`) ve `display_name` (varsa)
  - Tıklandığında: show list of transcripts where this speaker appears (başlık + timestamp). Backend istemi yok, sadece lokal DB sorgusu.
  - Long-press veya edit: `display_name` düzenleme dialogu — kaydedildiğinde `speakers.display_name` update edilir.

- `TranscriptScreen` (`src/features/transcript/presentation/screens/TranscriptScreen.tsx`):
  - Her transcript segmentin yanında `label` veya `display_name` göster (ör: "Hurşit (Voice-1)").
  - `display_name` değişince otomatik güncelleme — tek kaynak `speakers` tablosu.

## Veri Migration & Backward Compatibility
- Eğer mevcut deploylarda `speakers` tablosu yoksa migration script ekle (v1 → v2).
- Mevcut transcript segment yapısına `speaker_id` kolonu ekle (nullable) — yeni segmentler oluşturulurken set edilir.

## Test Planı
- Unit: cosine similarity hesaplama, embedding serialization/deserialization
- Integration (emüle edilmiş): küçük test WAV parçalarıyla segment → embedding → match akışı
- E2E: 3 konuşmacılı 1 dakikalık kayıt; UI'da 3 temp cluster oluşmalı; birine isim verildiğinde diğer session'da da eşleşme denenmeli

## Güvenlik & Gizlilik Notları
- Embedding'ler kişisel veriye dönüşebilir; Phase 13 kapsamında şifreli DB ve opt-in/opt-out politikası değerlendirilecek.
- Embedding'leri gerektiğinde silme opsiyonu sağlanmalı (`display_name` silindiğinde fingerprint koruma opsiyonları düşünülmeli).

## Zamanlama & Milestones (tahmini)
- Week 0.5: Native speaker engine proof-of-concept (Android) — embedding extraction from sample audio
- Week 1: JS bridge + DB schema + UI plumbing (Speaker list + naming)
- Week 1.5: Session clustering + matching + persistans
- Week 2: Integration tests + small device tests + tuning thresholds

## Kabul Kriterleri
- Otomatik diarization: aynı session içinde konuşmacılar ayrı clusterlara ayrılıyor
- Kullanıcı isimlendirmesi persistence ile başka sessionlarda eşleşiyor
- Transcript ekranında speaker etiketleri doğru gösteriliyor
- Hiçbir manuel enrollment adımı gerekmiyor