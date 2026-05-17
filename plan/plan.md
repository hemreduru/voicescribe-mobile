# VoiceScribe — Master Plan

> Bu dokuman uygulamanin tum yol haritasini, mevcut durumunu ve hedef sistemi tanimlar. Hem yeni bir gelistirici hem de gelecekteki Claude oturumlari icin tek referans noktasidir.

---

## 1. Vizyon

VoiceScribe; sesi **offline-first** olarak yakalayan, **on-device Whisper** ile transcribe eden, **local veya cloud LLM** ile ozetleyen ve transcript+ozet uzerinden **AI ile sohbet** edilebilen bir mobil uygulamadir.

**Temel akis:**
1. Kullanici ses kaydi alir (mikrofon -> PCM chunks)
2. Chunk'lar local Whisper.cpp ile transcribe edilir
3. Transcript local DB'ye yazilir
4. Local veya Cloud LLM transcript'i ozetler
5. Kullanici transcript+ozet baglaminda LLM ile sohbet eder (local veya cloud)
6. Internet bagliyken local'deki tum veriler backend'e push edilir ve **local DB sifirlanir** (hard delete, yer kazanmak icin)

---

## 2. Mimari Kararlar

| Konu | Karar | Gerekce |
|---|---|---|
| Sync sonrasi local DB | **Hard delete** | Yer kazanma onceligi. Sync ACK alindiktan sonra silinir; race koruma |
| Cloud AI provider | **Provider-agnostic** | `llm_providers` tablosu uzerinden OpenAI/Anthropic/OpenRouter pluggable, `.env` ile secim |
| Chat motoru | **Local + Cloud paralel** | Kullanici secer. On-device kucuk LLM (llama.cpp) + cloud LLM |
| Mobile architecture | Domain -> Data -> UI, BLoC pattern | Mevcut yapinin korunmasi |
| Backend architecture | Service-Repository pattern (Laravel 12) | Mevcut yapinin korunmasi |

---

## 3. Tech Stack

### Mobile — `/var/www/voicescribe-mobile`
- **Flutter** + Dart (SDK ^3.11.5)
- State: `flutter_bloc` + BLoC pattern
- Recording: `record` ^6.2.0
- On-device AI: `whisper_ggml_plus` ^1.5.2 (Whisper.cpp)
- Local DB: `sqflite` ^2.4.2 (SQLite)
- Auth storage: `flutter_secure_storage` ^9.2.4
- Routing: `go_router` ^17.2.2
- HTTP: Native Dart `HttpClient` (`sync_http_client.dart`)
- Waveform: `waveform_visualizer` ^1.0.0
- Codegen: `freezed`, `json_serializable`, `build_runner`
- i18n: ARB -> generated (en, tr)

### Backend — `/var/www/vsbackend`
- **Laravel 12** (PHP 8.2)
- **MySQL 8.x**
- Auth: **Laravel Sanctum** (JWT via `personal_access_tokens`)
- Pattern: Service-Repository

---

## 4. Mevcut Durum (DONE)

### Mobile
- [x] **Auth** — email+password login, secure token storage, refresh — `lib/data/services/auth/`
- [x] **Recording** — mikrofon -> PCM chunking -> live transcription UI — `lib/ui/features/recording/bloc/recording_bloc.dart`
- [x] **Local transcription** — Whisper.cpp, runtime model download — `lib/data/services/whisper_service.dart`
- [x] **Transcript viewer** — liste, arama, siralama (newest/oldest/longest), chunk detayi — `lib/ui/features/transcript/`
- [x] **Local summary** — cumle cikarma motoru — `LocalSummaryService` in `lib/data/services/summary_service.dart`
- [x] **Sync queue iskeleti** — pending/synced status, connectivity monitor, merge policy — `lib/data/services/sync/sync_queue_service.dart`
- [x] **Settings** — tema, dil, summary provider/length, model secimi
- [x] **SQLite persistence** (`sqflite`)
- [x] **i18n** — en, tr
- [x] **9 test dosyasi** — sync, mapper, bloc, widget tests

### Backend
- [x] **Auth endpoints** — `POST /auth/register`, `POST /auth/login`, `POST /auth/logout`, `GET /auth/me` — `app/Http/Controllers/Api/V1/AuthController.php`
- [x] **Transcripts CRUD** — list / get / upsert / update / soft-delete — `TranscriptController.php`
- [x] **Sync endpoints** — `POST /sync/push`, `POST /sync/pull`, `GET /sync/status` — `SyncController.php`
- [x] **DB tablolari** — `users`, `transcripts`, `transcript_chunks`, `summaries`, `transcript_statuses`, `llm_providers`, `personal_access_tokens`
- [x] `SummarizationService` sinifi tanimli (henuz wire edilmemis) — `app/Services/Summarization/SummarizationService.php`

---

## 5. Eksikler (TODO)

### Mobile
- [ ] `CloudSummaryService` implementasyonu (interface var, impl yok)
- [ ] **AI Chat feature** — `lib/ui/features/chat/` (ekran + BLoC + servis + repository)
- [ ] **On-device LLM** — llama.cpp Flutter binding (`llama_cpp_dart` veya FFI)
- [ ] Sync response parsing tamamlama
- [ ] **Hard-delete logic** — basarili sync sonrasi local kayitlarin silinmesi
- [ ] Audio chunk boyutu optimizasyonu (`pcm_chunker.dart` tuning)
- [ ] Model download progress UI iyilestirme

### Backend
- [ ] **Chat endpoints + tablolar** — `chats`, `chat_messages` migration + controller
- [ ] **Summarization proxy** endpoint'ini ac — `routes/api.php:38-40` uncomment + wire
- [ ] **LLM provider adapter'lari** — OpenAI, Anthropic, OpenRouter (LlmProviderAdapter interface)
- [ ] **Cloud chat proxy** — streaming SSE (`/chats/{id}/messages`)
- [ ] **Audio file upload** (opsiyonel, ileride kullanici isterse)
- [ ] **Refresh token** mekanizmasi (Sanctum default'u expire etmiyor)

---

## 6. Roadmap (Faz bazli)

### Faz 1 — Sync'i kapat (1-2 hafta)
**Hedef:** Offline-first dongusunun calismasi, hard-delete'in guvenli olmasi.

- Mobile
  - `sync_queue_service.dart`: sync response parsing tamamlanacak
  - Hard-delete logic: backend ACK aldiktan sonra local kayit silinir
  - Race protection: sync sirasinda yeni kayit gelirse queue'da kalir
- Backend
  - `/sync/push` ve `/sync/pull` payload sozlesmesi netlestirilecek
  - Conflict resolution stratejisi (last-write-wins veya server-authoritative)
- **E2E test:** offline kayit -> online'a gec -> backend'e yaz -> local sil -> app restart sonrasi liste bos

### Faz 2 — Cloud Summarization (1 hafta)
**Hedef:** Kullanici settings'ten cloud provider secip ozetleyebilsin.

- Backend
  - `LlmProviderAdapter` interface
  - OpenAI ve Anthropic adapter'lari
  - `POST /summarize` endpoint'ini ac (routes/api.php:38-40)
  - `summaries` tablosundaki `provider_id`, `model`, `token_count` alanlari kullanilacak
- Mobile
  - `CloudSummaryService` implement
  - Settings'te provider + model + token limit secimi

### Faz 3 — Cloud Chat (2 hafta)
**Hedef:** Kullanici transcript+ozet uzerinden cloud LLM ile sohbet edebilsin.

- Backend
  - `chats` ve `chat_messages` migration + modeller
  - `GET/POST /chats` CRUD
  - `POST /chats/{id}/messages` — **streaming SSE** endpoint
  - Transcript+summary context injection (system prompt)
- Mobile
  - `lib/ui/features/chat/` feature klasoru
  - `ChatScreen`, `ChatBloc`, `ChatRepository`, `CloudChatService`
  - **Streaming UI** — token-by-token render

### Faz 4 — Local Chat (2-3 hafta)
**Hedef:** Offline'da da AI ile sohbet edebilmek.

- llama.cpp Flutter binding arastirmasi (`llama_cpp_dart` vs FFI)
- Kucuk model secimi (Phi-3-mini, Gemma-2B, Llama-3.2-1B) — runtime download
- `LocalChatService` implement
- Settings'te local/cloud chat toggle
- Disk uyarisi (2-4 GB model)

### Faz 5 — Polish (1 hafta)
- Audio chunk size tuning (latency vs accuracy)
- Model download progress UI
- Error handling & retry mekanizmalari
- Genisletilmis integration testler
- Performance profiling

---

## 7. Mimari Notlar

- **BLoC pattern** korunacak — her feature icin `*_bloc.dart` + `*_event.dart` + `*_state.dart`
- **Repository abstraction** — domain katmaninda interface, data katmaninda implementation
- **Freezed models** — immutable, copyWith, equality. Her degisiklikten sonra `dart run build_runner build --delete-conflicting-outputs`
- **Domain -> Data -> UI** katmanli yapi
- AGENTS.md'deki CI/codegen adimlari takip edilecek
- Provider-agnostic cloud AI: Backend'de `LlmProviderAdapter` interface, mobile'da bunu kullanan tek `CloudSummaryService` / `CloudChatService`

---

## 8. Riskler ve Edge Case'ler

| Risk | Mitigasyon |
|---|---|
| Hard delete + offline race: sync sirasinda kullanici offline'a duserse veri kaybi | Sync ACK alindiktan sonra silme; ACK gelmezse retry kuyrugunda kalir |
| Local LLM model boyutu (2-4 GB) cihaz dolduruyor | Indirme oncesi disk uyarisi, model silme opsiyonu |
| Streaming SSE Laravel'de native degil | `symfony/event-source` veya `react/http` paketi |
| Whisper model degisikliginde transcript kalitesi degisir | Model degistirilince kullanici uyarilir, eski transcript'ler etkilenmez |
| Cloud provider API limit/cost | Kullanici basina rate limit + token sayaclari (`summaries.token_count` zaten var) |
| Conflict resolution (ayni transcript hem local hem backend'de degismis) | Faz 1'de net karar gerekiyor — onerilen: server-authoritative |

---

## 9. Onemli Dosya Yollari

### Mobile
- Domain models: `lib/domain/models/domain.dart`
- Sync core: `lib/data/services/sync/sync_queue_service.dart`
- Whisper: `lib/data/services/whisper_service.dart`
- Summary: `lib/data/services/summary_service.dart`
- Recording: `lib/ui/features/recording/bloc/recording_bloc.dart`
- DI/Bootstrap: `lib/main.dart`
- Geliştirici rehberi: `AGENTS.md`

### Backend
- Routes: `routes/api.php`
- Controllers: `app/Http/Controllers/Api/V1/{Auth,Transcript,Sync}Controller.php`
- Migrations: `database/migrations/`
- Summarization service: `app/Services/Summarization/SummarizationService.php`
- Env: `.env`

---

## 10. Tahmini Toplam Sure

**~7-9 hafta** (tek gelistirici, full-time degilse %50-100 fazlasi)

| Faz | Sure |
|---|---|
| 1. Sync | 1-2 hafta |
| 2. Cloud Summary | 1 hafta |
| 3. Cloud Chat | 2 hafta |
| 4. Local Chat | 2-3 hafta |
| 5. Polish | 1 hafta |

---

*Son guncelleme: 2026-05-17*
