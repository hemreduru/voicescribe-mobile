# VoiceScribe — Invisible UX / Proactive Behavior Audit

> Phase 2, 2026-06-15. Walked the whole journey (bootstrap → auth → record →
> transcript → summary → chat → settings → sync) against the proactive-UX
> framework. Each finding: **what's wrong · why it hurts · fix · impact · effort
> · risk**. Scope = *behavior/UX*; correctness & perf bugs live in
> `optimization-plan.md` (referenced, not duplicated). Items flow into
> `ux-backlog.md`.

Legend — Impact/Effort/Risk: H/M/L.

---

## A. Automatic triggering (the headline class)

### A1. Summary does not auto-start after transcription ⭐ flagship
- **Wrong:** Summary is fully manual — open detail → Summary tab → tap. Nothing
  fires when a recording finishes transcribing.
- **Why it hurts:** This is the product's core value (record → get structured
  minutes). Every competitor (Plaud AutoFlow, Granola, Otter) auto-produces it.
  Users who never open the Summary tab never see the feature.
- **Fix:** When a transcript transitions to `completed` (backlog drained) and has
  non-empty text, auto-dispatch summary generation via the existing
  `GenerateSummaryUseCase`/router. Gate by a new pref `autoSummarize` (default on)
  and only when the chosen engine is usable (local model present, or cloud +
  synced + authed). Debounce; never auto-run twice; show progress on the card.
- **Impact H · Effort M · Risk M** (must not auto-trigger cloud cost without
  consent — default on but respect provider + opt-out).

### A2. Cloud auto/manual summary silently fails until synced
- **Wrong:** Cloud summary throws `summaryNotSynced` if `remoteId` is null. With
  auto-summary this would fail right after recording (sync hasn't landed yet).
- **Why it hurts:** Confusing dead-end; user did nothing wrong.
- **Fix:** If cloud + not yet synced, **queue** the summary to run after the next
  successful sync push (hook `SyncEvent.success`), with a clear pending state
  ("Will summarize after upload"). Or transparently push that transcript first.
- **Impact H · Effort M · Risk M.**

### A3. Provider smart-default only re-evaluates when Settings opens
- **Wrong:** local→cloud fallback for unsupported devices runs in
  `SettingsBloc._loadLocalLlmEntry` — only when the user visits Settings.
- **Why it hurts:** A user who never opens Settings keeps `summaryProvider=local`
  on a device that can't run it → summary/chat just fail.
- **Fix:** Resolve the smart default at **bootstrap** (or onboarding), once the
  device profile is known, and persist it. Settings stays a re-check.
- **Impact M · Effort M · Risk L.**

## B. Smart defaults

### B1. No first-run defaults chosen for the user
- **Wrong:** No onboarding → all 5 prefs sit at static defaults
  (`summaryProvider=local`, `transcriptionLanguage=auto`, model=base) regardless
  of device or user.
- **Why it hurts:** A low-end device defaults to a local engine it can't run; a
  Turkish user's language isn't pre-confirmed; the local/cloud choice is never
  framed.
- **Fix:** Phase 3 onboarding picks language, local/cloud (tier-aware
  *recommendation*), theme, and primes permissions; writes prefs once.
- **Impact H · Effort H · Risk L.**

### B2. Transcription language defaults to `auto` with no nudge
- **Wrong:** `auto` is a fine default, but bilingual TR/EN accuracy is a known
  weak spot and the user is never offered the per-session forced-language choice
  contextually.
- **Fix:** Offer a quick language chip on the recording screen (Auto/TR/EN) so a
  user can force a language for a known-monolingual session. Low effort, high
  perceived control. **Impact M · Effort L · Risk L.**

## C. Friction / taps

### C1. Summary buried two levels deep
- **Wrong:** Open transcript → switch to Summary tab → tap generate.
- **Fix:** With A1 (auto), the summary is usually already there. Also surface a
  "Summary" affordance on the transcript card / recording "recent" item so the
  most valuable output is one tap, not three. **Impact M · Effort M · Risk L.**

### C2. Recording-screen empty state is a bare card
- **Wrong:** "No recordings" is a plain `AppCard` with text, not the shared
  `EmptyState` used elsewhere — inconsistent and uninformative for first use.
- **Fix:** Use `EmptyState` with an icon + a one-line "Tap the mic to start your
  first recording." **Impact L · Effort L · Risk L.**

## D. State & feedback

### D1. No transcription progress on the recording screen
- **Wrong:** The bloc computes `isTranscribing`, `transcribedProgressChunks`,
  `estimatedTranscriptionRemaining`, but the recording screen renders none of it.
  After stop, the user sees nothing happening on the home screen.
- **Fix:** Show a compact "Transcribing… X/Y · ~Zs left" strip on the recording
  screen (reuse the transcript-screen `_TranscriptionProgressBar` pattern).
  **Impact M · Effort L · Risk L.**

### D2. Chat answer is not streamed
- **Wrong:** Optimistic user bubble + "thinking", then the whole answer pops in.
- **Why it hurts:** Feels laggy/dead during multi-second generation; streaming is
  perceived 40–60% faster.
- **Fix:** Stream tokens (cloud SSE on backend; on-device incremental from
  `flutter_gemma`). Typing indicator → stream. **Impact M · Effort H · Risk M**
  (needs backend SSE; can phase: on-device first or pseudo-stream).

### D3. Long summary has progress; cloud summary has none
- **Wrong:** On-device map-reduce shows "3/7"; cloud shows only a spinner for up
  to 60s.
- **Fix:** Indeterminate-but-labeled state ("Summarizing on the server…") and, if
  backend supports it, stream partial summary. **Impact L · Effort M · Risk L.**

## E. Error prevention & recovery

### E1. Errors surfaced as raw `error.toString()` in Settings & elsewhere
- **Wrong:** `SettingsBloc` shows `errorMessage: error.toString()` (model switch,
  save prefs, logout, LLM download). Not localized, not friendly. (Overlaps
  optimization-plan A6 for recording/summary; Settings is additional.)
- **Fix:** Map to `AppErrorCode` + localized copy; reserve raw text for logs.
  **Impact M · Effort M · Risk L.**

### E2. Sync 401 has no re-login path (also opt-plan C5)
- **Wrong:** A 401 during sync loops as generic "failed" forever.
- **Fix:** On 401, drop session → route to `/auth` with a toast. **Impact M ·
  Effort M · Risk M.** (Confirm against opt-plan; implement once.)

### E3. No retry affordance for a failed summary
- **Wrong:** Summary failure shows a snackbar; the user must find the button
  again. **Fix:** Inline error card with one-tap "Try again" in the Summary tab.
  **Impact L · Effort L · Risk L.**

## F. Empty & first-use states

### F1. AI tab doesn't explain what it does
- **Wrong:** Empty AI tab shows "no sessions" but never says it answers questions
  **over your own transcripts**, nor that you need recordings first.
- **Fix:** First-use explainer in the empty state: what it does + "record
  something first" CTA when there are zero transcripts. **Impact M · Effort L ·
  Risk L.**

### F2. No contextual coach-marks on first record / first summary
- **Fix:** One-time lightweight hint ("Recording transcribes live; summary is
  ready when it finishes"). Tie to onboarding-seen flag. **Impact L · Effort M ·
  Risk L.**

## G. Permissions
- **Already good:** mic+notification primed on first recording-screen entry,
  sequential, re-request on tap, permanently-denied → Open Settings. ✅
- **G1.** Move the *rationale* into onboarding (priming screen) so the OS dialog
  isn't the first explanation. **Impact M · Effort M (part of Phase 3) · Risk L.**

## H. Continuity & background
- **Already good:** foreground service keeps transcription draining when
  backgrounded after stop; orphan-chunk recovery on launch. ✅
- **H1. No completion notification.** When a long transcription/summary finishes
  while backgrounded, nothing tells the user. **Fix:** post a local notification
  "Transcript ready / Summary ready" (we already hold notification permission +
  `flutter_foreground_task`). **Impact M · Effort M · Risk L.**

## I. Perceived performance
- **Already good:** skeletons on transcript/AI lists, fade route transitions,
  optimistic chat bubble, decoupled waveform repaint. ✅
- **I1.** Recording-screen recent list + bootstrap could use the existing skeleton
  while the first snapshot loads. **Impact L · Effort L · Risk L.**

## J. Accessibility & feel
- **Already good:** haptics tokens wired on record/selection; tabular timer;
  `semanticLabel` on cards/buttons. ✅
- **J1.** No verified TalkBack pass / dynamic-type audit (also prod-readiness P2).
  **Fix:** label icon-only buttons, test largest font scale, dark-mode contrast.
  **Impact M · Effort M · Risk L.**
- **J2.** Hardcoded TR/EN in `transcript_screen.dart:1212` (`_statusHelpDescription`)
  bypasses l10n. **Fix:** move to ARB. **Impact L · Effort L · Risk L.**

## K. Discoverability
- **K1.** Local vs cloud difference invisible (see competitive analysis). **Fix:**
  trade-off copy at the toggle + engine label on results. **Impact M · Effort L ·
  Risk L.**
- **K2.** Transcription-model choice (base/small/…) has device gating but no plain
  "what do I gain/lose" guidance beyond the catalog. **Fix:** short per-model
  benefit line (speed vs accuracy vs size). **Impact L · Effort L · Risk L.**

---

## Seed findings from the roadmap — verified & folded in
(Per the task; not re-implemented here, but tracked so they aren't lost.)
- ~2200-char silent truncation on large transcripts → **must fix before A1 auto-
  summary** (auto-summary on a truncated transcript = silently wrong output).
- Local summary JSON parse failures (`action_items`/`agenda_items` need a lenient
  converter) → the UI already hides raw JSON (shows "unavailable"), but the
  *parse* should be hardened so good content isn't dropped.
- `summaryProvider` cross-cuts summary AND chat routing — documented; any
  provider change in onboarding/settings affects both (intended, but label it).
- Cloud summary requires synced transcript — see A2.
- Gemma only enabled on `performance` device tier — informs B1 recommendation.

## Priority shortlist (detail in `ux-backlog.md`)
1. **A1** auto-summary after transcription (+`autoSummarize` pref) — flagship.
2. **B1/Phase 3** onboarding wizard (defaults + priming + local/cloud framing).
3. **A2/A3** cloud-summary-after-sync queue + bootstrap smart default.
4. **D1** recording-screen transcription progress; **H1** completion notification.
5. **F1/K1** AI-tab explainer + local/cloud legibility.
6. **D2** chat streaming.
7. Polish: **C2, E1, E3, I1, J1, J2, K2**.
