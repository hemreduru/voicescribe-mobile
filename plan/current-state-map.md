# VoiceScribe — Current State Map

> Snapshot 2026-06-15. The user journey, every screen's states, and — critically —
> **what is automatic vs manual today**. This is the baseline the invisible-UX
> audit (`invisible-ux-audit.md`) measures against. Cross-reference the known
> bug/perf backlog in `optimization-plan.md` (do not duplicate those items).

## Architecture (the contract)
Domain → Data → UI. Each feature: BLoC/Cubit (`*_bloc.dart` event/state).
`go_router` shell. freezed/json_serializable + build_runner. ARB i18n (en/tr).
Repository abstraction in domain, impl in data. Snapshot stream
(`watchSnapshot()`) is the single source of truth the UI subscribes to.

## `AppPreferences` (domain.dart) — the entire persisted config surface
5 fields, defaults in **bold**:
- `summaryProvider`: **local** | cloud  ← also routes CHAT (cross-cutting)
- `themeMode`: **system** | light | dark
- `localePreference`: **system** | en | tr
- `transcriptionModel`: tiny | **base** | small | medium | large-v3 | large-v3-turbo
- `transcriptionLanguage`: **auto** | tr | en

**There is no first-run/onboarding flag.** No `hasSeenOnboarding`,
no first-launch branching anywhere (`grep` confirms zero matches).

---

## Journey & screens

### 0. Bootstrap (`/`, BootstrapGate)
- States: initializing / downloading-model (progress %) / failed (retry button) / ready.
- Downloads the Whisper model on first launch. Auto-proceeds when ready.
- ⚠️ Known: bootstrap awaits a full network refresh before "ready" (perf B4).

### 1. Auth (`/auth`)
- Email + password login; secure token storage. `APP_ENV=development` =
  passwordless. Error states surfaced. **No** register/forgot-password UI in app.

### 2. Recording (`/recording`) — home
- **Permission priming**: requests mic + notification on first entry
  (post-frame), sequentially. On record tap, re-requests mic; denied →
  snackbar with "Open settings" if permanently denied. ✅ Good.
- Title field, `PulseRecordButton`, duration display, pause/resume + stop,
  live `AudioVisualizer` (rebuilt ~8/s independent of the 1s tick). ✅
- **AUTO**: each 15s audio chunk → saved → transcribed immediately (live,
  during recording). Chunk recovery on app restart (re-transcribes orphans). ✅
- **AUTO**: on stop → transcript finalized, status derived, `scheduleSync()`.
- Recent recordings (last 3). Empty state = plain `AppCard` text (not `EmptyState`).
- ❌ **No transcription progress/ETA shown here** — the bloc computes
  `isTranscribing` / `estimatedTranscriptionRemaining` but the recording screen
  doesn't render them (they only appear on the transcript card/detail).
- ❌ First-time users get **no hint** of what the button does or what happens next.

### 3. Transcript list (`/transcript`)
- Search, sort (newest/oldest/longest), filter (all/ready/processing/issue).
- Skeleton on first load; `EmptyState` for empty + no-match. ✅
- Cards show status pill, date, duration, **live progress bar + device ETA**
  while transcribing, 2-line preview. ✅
- Multi-select delete (long-press) with confirm dialog. Pull-to-refresh.
- Detail = modal bottom sheet (compact) or right pane (tablet, ≥1000).
- Detail tabs: **Transcript** | **Summary**. Status pill, metric pills,
  progress bar, transcription-error banner with **one-tap retry**. ✅
- Status help sheet (⚠️ hardcoded TR/EN strings, l10n bypass).

### 4. Summary (Summary tab inside transcript detail)
- ❌ **FULLY MANUAL**: user must open detail → Summary tab → tap "Generate
  summary". No auto-trigger after transcription completes. *(This is the exact
  canonical gap the task names.)*
- Routing (`SummaryServiceRouter`): `summaryProvider=='cloud'` → cloud, else local.
- Multi-step progress shown for long on-device map-reduce ("Özetleniyor 3/7"). ✅
- **Cloud summary requires a synced transcript** (`remoteId`); otherwise throws
  `summaryNotSynced`. Offline/auth/empty/invalid each map to an `AppErrorCode`. ⚠️
- Structured `MeetingSummary` rendered via `MeetingSummaryView`; JSON that fails
  to parse shows a clean "unavailable" message (never raw JSON). ✅
- **Smart default**: if device can't run on-device LLM, `summaryProvider` auto-
  switches local→cloud on settings load. ✅ (but only triggers when Settings opens)

### 5. AI chat (`/ai`)
- Sessions list (DB-persisted) + conversation. Two-pane on tablet, full-screen
  push on phone. New chat, delete-with-confirm. `EmptyState` for no sessions /
  no selection. ✅
- Routing: `summaryProvider=='local'` → on-device RAG (`LocalChatService`, no
  backend session, in-memory); else cloud (`ChatRepository.sendMessage`).
- **Optimistic** user message + "thinking"; ❌ **answer is NOT streamed** — it
  appears all at once when the full response returns. Sources attribution shown.
- ❌ Empty AI tab doesn't explain it answers over **your transcripts** or that
  you need recordings first.

### 6. Settings (`/settings`)
- Summary provider (local/cloud), theme, app language, transcription model
  (device-tier gated, download progress), transcription language, on-device LLM
  download (Gemma), manual sync, pending-sync count, last-sync time, logout.
- Errors surfaced as `errorMessage` strings (some raw `error.toString()`).

### 7. Sync (background, `SyncQueueService`)
- Debounced + 5-min periodic + connectivity-triggered. Push pending/failed,
  pull, merge policy. `GlobalSyncFeedbackHost` surfaces app-wide feedback.
- ⚠️ Known issues in `optimization-plan.md`: race (A1), double cycle, 401 has no
  re-login path (C5), unbounded push batch (B8).

---

## Auto vs Manual — the scoreboard

| Step | Today | Ideal |
|---|---|---|
| Chunk → transcribe | **AUTO** ✅ | auto |
| Stop → finalize + schedule sync | **AUTO** ✅ | auto |
| Orphan chunk recovery on launch | **AUTO** ✅ | auto |
| Transcribe done → **summarize** | **MANUAL** ❌ | auto (opt-out) |
| Summary done → chat ready | n/a (chat is global) | contextual entry |
| Chat answer rendering | batch ❌ | streamed |
| local↔cloud provider pick | manual + 1 smart fallback | tier-aware default at onboarding |
| Model/language pick | manual | language inferred / set at onboarding |
| First-run configuration | **none** ❌ | onboarding wizard |

## Deliverables produced from this map
- `invisible-ux-audit.md` — the gaps above, expanded with fix/impact/effort/risk.
- `ux-backlog.md` — prioritized, dedup'd against `optimization-plan.md`.
