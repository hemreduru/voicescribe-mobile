# VoiceScribe — UX Backlog (prioritized)

> Phase 4, 2026-06-15. Merges `ux-competitive-analysis.md` + `invisible-ux-audit.md`
> + Phase 3 onboarding. Ordered by impact × (1/risk), deploy-unblocking and
> proactive-behavior items first. Dedup'd against `optimization-plan.md` (bugs/perf)
> and `production-readiness.md` (release gates) — those stay owned there.
>
> **Decisions (2026-06-15, confirmed by user):** UX-01 `autoSummarize` ships
> **default-on**. UX-09 chat streaming scope = **both** on-device + cloud (cloud
> needs vsbackend SSE — separate repo, sequenced later). Loop runs in the
> suggested order.
>
> Status: `todo` / `in-progress` / `done`. Each item is a `/goal` unit for the loop.
> Code is English; user-facing strings TR+EN. Every item must leave the tree green
> (`flutter analyze` 0 issues, `flutter test`, `flutter build apk --debug`).

---

### UX-01 — Auto-summarize after transcription completes ⭐
- **Category:** invisible-ux
- **Problem:** Summary is fully manual; the core output is invisible to most users.
- **Goal / success:** When a transcript reaches `completed` with non-empty text
  and `autoSummarize` is on and the chosen engine is usable, a summary is
  generated automatically (no tap), with progress on the card and exactly one run
  per transcript. Verified on device: record → stop → summary appears.
- **Design:** New `AppPreferences.autoSummarize` (default `true`). A coordinator
  (in the recording/transcript-detail data flow or a small service listening to
  the snapshot stream) detects the `transcribing→completed` edge and dispatches
  `GenerateSummaryUseCase` via `SummaryServiceRouter`. Guard: skip if a summary
  already exists, if generation in-flight, or engine unusable (→ see UX-03/UX-04).
  **Depends on truncation fix** (see UX-12) so auto output isn't silently partial.
- **Files:** `domain/models/domain.dart` (pref + normalize), build_runner;
  `data/services/.../summary*`; `ui/features/transcript/bloc/transcript_detail_bloc.dart`
  or a new listener; settings toggle + ARB.
- **Impact H · Effort M · Risk M · Deps:** UX-12, UX-04.
- **Status: done (pending on-device E2E).** Added `AppPreferences.autoSummarize`
  (default on, persisted), `AutoSummaryCoordinator` (watches the snapshot stream,
  runs `GenerateSummaryUseCase` on the `completed` edge with full guards: existing
  summary, in-flight, session-failed, engine-ready). Cloud naturally defers until
  `remoteId`+token appear via a later snapshot — **this also covers UX-04**.
  Settings toggle + TR/EN strings. +5 coordinator unit tests. analyze clean,
  115 tests green, APK builds. Remaining: device E2E (record→auto-summary) with a
  logged-in session + local model or cloud key.

### UX-02 — Interactive onboarding wizard (Phase 3)
- **Category:** onboarding
- **Problem:** No first-run experience; defaults never tuned to device/user;
  local-vs-cloud never framed; permissions explained only by the OS dialog.
- **Goal / success:** First launch shows a branded, skippable wizard; on finish,
  prefs are persisted and a `hasSeenOnboarding` flag prevents re-show (re-openable
  from Settings). Cold launch on a fresh install lands in the wizard, not recording.
- **Design (slides, all using design-system tokens / shared widgets / TR+EN):**
  1. **Value** — 2–3 slides with *real* UI mockups: "Record → live transcript",
     "Structured minutes, automatically", "Ask questions about your recordings".
  2. **Language** — app language + transcription language (Auto/TR/EN), TR/EN
     pre-highlighted by device locale.
  3. **AI engine** — On-device (private, offline, free) vs Cloud (faster, more
     accurate, needs login). **Tier-aware recommendation** from
     `resolveDeviceProfile()`; writes `summaryProvider`.
  4. **Theme** — system/light/dark preview.
  5. **Permissions priming** — rationale screen → triggers mic + notification
     requests (the contextual ask).
- **Architecture:** new `lib/ui/features/onboarding/` (bloc/cubit + views),
  `go_router` gated route before `/recording` driven by the flag (mirror `/auth`
  full-screen + fade), reuse `AppPage`/`AppButton`/`AppCard`/`AppSegmentedControl`.
- **Files:** new feature dir; `app_router.dart`; `domain/models/domain.dart`
  (`hasSeenOnboarding`) + build_runner; repository `savePreferences`; ARB; settings
  entry to re-open.
- **Impact H · Effort H · Risk L · Deps:** none (UX-03 reuses its engine-pick copy).
- **Status: done.** `onboarding` feature (cubit+5 slides), `hasSeenOnboarding`
  pref, go_router `/onboarding` gate via `BootstrapState.onboardingComplete`,
  "Replay intro" in Settings, TR/EN. +5 cubit tests; widget tests fixed.
  analyze clean, 120 tests green, APK builds. **Device-verified on tablet** (all
  5 slides, TR transcription-language smart default, on-device recommended,
  finish→app, relaunch does not re-show).

### UX-03 — Resolve provider smart-default at bootstrap
- **Category:** invisible-ux
- **Problem:** local→cloud fallback for unsupported devices only runs when Settings
  opens; users who skip Settings keep a broken `local` choice.
- **Goal / success:** After device profile resolves at bootstrap (or onboarding
  finish), an unsupported-device `local` pref is auto-corrected to `cloud` once and
  persisted. Verified: low-tier device never stuck on a failing local engine.
- **Files:** `ui/features/bootstrap/bloc/bootstrap_bloc.dart` (or onboarding
  finalize); reuse `LocalLlmModelService.catalogEntry()`; repository.
- **Impact M · Effort M · Risk L · Deps:** UX-02 (shared logic).
- **Status: done.** `BootstrapBloc` now resolves the provider smart-default at
  launch (local→cloud when `isSupported()` is false), folded into the existing
  single boot-time preference write. +2 unit tests (both branches). analyze
  clean, 122 tests green. (No UI change; test device is a capable tier.)

### UX-04 — Queue cloud summary to run after sync
- **Category:** invisible-ux
- **Problem:** Cloud summary throws `summaryNotSynced` when `remoteId` is null —
  fails right after recording, especially under auto-summary (UX-01).
- **Goal / success:** When cloud is selected and the transcript isn't synced, the
  summary is deferred with a clear "Will summarize after upload" state and runs on
  the next `SyncEvent.success` for that transcript. No dead-end error.
- **Files:** `data/services/sync/sync_queue_service.dart` (event hook);
  summary trigger/coordinator; transcript_detail state + ARB.
- **Impact H · Effort M · Risk M · Deps:** UX-01.

### UX-05 — Transcription progress on the recording screen
- **Category:** invisible-ux / polish
- **Problem:** After stop, the home screen shows nothing while transcription drains;
  the bloc already computes progress + ETA.
- **Goal / success:** A compact "Transcribing… X/Y · ~Zs left" strip appears on the
  recording screen whenever `isTranscribing`; hides when done.
- **Files:** `ui/features/recording/views/recording_screen.dart` (reuse
  `_TranscriptionProgressBar`); ARB if new strings.
- **Impact M · Effort L · Risk L.**
- **Status: done.** Added a self-rebuilding `_TranscriptionStatusStrip` (label +
  progress bar + "X/Y · ~ETA") driven by the bloc's existing progress getters;
  extracted `humanizeEtaUnit` to a shared util. analyze clean, 122 tests green.
  **Device-verified on tablet** (showed "Yazıya dökülüyor 17/18" while recording).

### UX-06 — Completion notifications (transcript / summary ready)
- **Category:** invisible-ux
- **Problem:** Long transcription/summary finishing in the background is silent.
- **Goal / success:** A local notification fires when a backgrounded transcript
  finishes transcribing and (if auto) when its summary is ready; tapping opens it.
- **Files:** `data/services/background_work_service.dart` /
  `flutter_foreground_task`; recording/summary completion hooks; ARB; deep-link.
- **Impact M · Effort M · Risk L · Deps:** UX-01 for the summary-ready case.

### UX-07 — AI-tab first-use explainer + local/cloud legibility
- **Category:** competitive-feature / invisible-ux
- **Problem:** AI tab never says it answers over *your transcripts*; local vs cloud
  difference invisible across summary + chat.
- **Goal / success:** Empty AI state explains the feature and shows "record first"
  when zero transcripts exist; a one-line trade-off sits at the provider toggle;
  summary/chat results show an engine label (On-device/Cloud from `providerKey`).
- **Files:** `ui/features/ai/views/ai_screen.dart`,
  `ui/features/settings/views/settings_screen.dart`,
  `ui/features/transcript/widgets/meeting_summary_view.dart`; ARB.
- **Impact M · Effort L · Risk L.**
- **Status: done.** AI empty state explains answers come from your transcripts
  and shows a "record something first" nudge when there are zero transcripts.
  Engine label on summaries already existed (cloud/on-device StatusPill);
  provider trade-off copy already at the Settings toggle. analyze clean, 122
  tests green. **Device-verified** (improved empty-state copy on AI tab).

### UX-08 — Per-session language chip on recording
- **Category:** polish
- **Problem:** Forcing TR/EN for a known-monolingual session needs a Settings trip.
- **Goal / success:** Auto/TR/EN chip on the recording screen sets the session
  language via `setTranscriptionLanguage` (doesn't overwrite the saved default
  unless chosen). Verified the forced language is applied to the next chunk.
- **Files:** `recording_screen.dart`, `recording_bloc.dart`/transcription service; ARB.
- **Impact M · Effort L · Risk L.**
- **Status: done.** Added a `currentTranscriptionLanguage` getter to the service
  and an Auto/TR/EN selector on the recording screen (hidden while recording);
  applies session-only via `setTranscriptionLanguage`, seeded from the saved
  default, no persistence. analyze clean, 122 tests green. **Device-verified**
  (showed Türkçe default, switched to Otomatik on tap).

### UX-09 — Stream chat answers
- **Category:** competitive-feature
- **Problem:** Answers render in one batch; feels laggy (streaming ≈ 40–60% faster
  perceived).
- **Goal / success:** Typing indicator → tokens stream into the bubble; TTFT target
  < ~800 ms. Phase: on-device incremental first; cloud SSE when backend supports it.
- **Files:** `ui/features/ai/bloc/chat_cubit.dart`, `conversation_view.dart`,
  `data/services/chat/local_chat_service.dart`, chat repository/backend SSE.
- **Impact M · Effort H · Risk M · Deps:** backend SSE for cloud path.

### UX-10 — Localize Settings (and stray) error messages
- **Category:** polish
- **Problem:** `SettingsBloc` surfaces raw `error.toString()`; not localized.
- **Goal / success:** Failures map to `AppErrorCode` + localized copy; raw text only
  in logs. **Files:** `settings_bloc.dart`, `domain/models/app_error.dart`,
  `error_messages.dart`, ARB. **Impact M · Effort M · Risk L.**

### UX-11 — Inline summary retry + recording empty state + skeletons + l10n fix
- **Category:** polish (bundled small wins)
- **Goal / success:** (a) Summary failure shows an inline "Try again" card (E3);
  (b) recording "no recordings" uses shared `EmptyState` (C2/F-style);
  (c) recording recent-list/bootstrap skeleton on first snapshot (I1);
  (d) move `_statusHelpDescription` hardcoded TR/EN to ARB (J2).
- **Files:** `recording_screen.dart`, `transcript_screen.dart`, ARB.
- **Impact L · Effort L · Risk L.**

### UX-12 — Fix large-transcript silent truncation (PREREQ)
- **Category:** invisible-ux (correctness-adjacent; overlaps optimization-plan)
- **Problem:** ~2200-char silent truncation feeding summarization → auto-summary
  would produce silently partial minutes.
- **Goal / success:** No silent truncation; long transcripts summarize via the
  existing map-reduce path end-to-end. **Files:** summary chunker / use case.
- **Impact H · Effort M · Risk M · Deps:** blocks UX-01.
- **Status: done** (commit `ae7345c`). Map step now uses budget-sized windows
  (no growth + no per-window truncation); coverage is a coherent contiguous
  prefix on-device, cloud stays lossless. +coverage unit test. analyze clean,
  110 tests green, debug APK builds.

### UX-13 — Accessibility pass (TalkBack / dynamic type / contrast)
- **Category:** polish (also prod-readiness P2)
- **Goal / success:** Icon-only controls labeled; UI holds at largest font scale;
  dark-mode contrast verified. **Impact M · Effort M · Risk L.**

---

## Suggested execution order
1. **UX-12** (prereq) → **UX-01** (flagship auto-summary)
2. **UX-02** onboarding → **UX-03** bootstrap default
3. **UX-04** cloud-after-sync → **UX-05** recording progress → **UX-06** notifications
4. **UX-07** AI explainer / legibility → **UX-08** language chip
5. **UX-09** chat streaming
6. **UX-10**, **UX-11**, **UX-13** polish

## Ask-before-proceeding items (destructive / direction-setting)
- **UX-01 default `autoSummarize=true`** — auto-runs the engine (cloud may incur
  backend cost) without an explicit tap. Confirm default-on vs default-off.
- **UX-09 cloud streaming** needs backend SSE work (separate repo). Confirm scope.
Everything else follows established UX best practice → proceed without asking.
