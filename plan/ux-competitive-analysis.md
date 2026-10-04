# VoiceScribe — Competitive UX Analysis

> Phase 1, 2026-06-15. Web research across transcription + AI-note apps (cloud
> and on-device). Goal: harvest proven UX patterns and translate each into a
> concrete VoiceScribe change. Hardware devices (Plaud) and desktop tools
> (MacWhisper/superwhisper) included where the *interaction pattern* transfers.

## The one pattern that matters most: post-capture autoflow

Every leading product **auto-runs the pipeline after capture** — the user
records, and transcript + summary appear without a button press.

- **Plaud "AutoFlow"** — "automatically generates the transcript and summary once
  the audio is in the app," then can even email it. Custom + prebuilt summary
  templates. → *VoiceScribe's summary is fully manual; this is the #1 gap.*
- **Granola** — "when the meeting ends, it combines what you jot with what it
  captured to produce notes"; **no setup, no button**; template-structured output.
- **Notta** — "does the heavy lifting without needing to click any buttons";
  praised clean UI; structured AI notes + mind maps; strong **multilingual**
  (matches our TR/EN bilingual reality).
- **Otter** — "Automated Summary" + "Action Items" are *core*, not opt-in;
  reviewers call the UI clumsy (anti-pattern: don't bury actions).
- **AudioPen** — auto-summary for paid users; rewrites rambling into structured
  text; **style/tone presets**; lauded clean, seamless UX.

**Translation → VoiceScribe:** when a recording's transcription finishes,
**auto-trigger summary generation** (respecting the on-device/cloud preference
and a user opt-out). This is the canonical "invisible UX" item and seeds the
backlog's top priority.

## Local vs cloud, made legible

- **superwhisper** exposes the choice with framed trade-offs: *local = privacy +
  offline, more battery; cloud = faster + more accurate, needs connectivity.*
- **MacWhisper** removes the choice entirely (pure on-device) to keep it simple.

**Translation → VoiceScribe:** our single `summaryProvider` toggle silently
governs both summary AND chat, and the difference (private/offline vs
accurate/needs login+sync) is never explained. Add a one-line trade-off
description at the toggle and at onboarding; surface the active engine on the
summary/chat result ("On-device" / "Cloud"). We already tag `providerKey`.

## Onboarding & permissions

- Carousels should show **unique value**, not repeat what's visible elsewhere;
  real screens beat generic benefit slides.
- **Permission priming**: explain *why* right before the feature needs it; don't
  bombard at launch. Babbel asks for mic only when the user reaches speaking
  practice. Notification ask can reduce onboarding drop-off.

**Translation → VoiceScribe:** our recording screen already primes mic +
notification reasonably. The onboarding wizard (Phase 3) should: (1) show 2–3
value slides with *real* UI, (2) let the user pick language + local/cloud (with
the trade-off copy) + theme, (3) prime mic/notification with a rationale screen
right before first record — not a launch dialog dump.

## Output structure & templates

- Plaud/Granola/Otter all lean on **structured output** (key points, decisions,
  action items, mind maps) and **templates/tone**. We already have
  `MeetingSummary` (agenda/action items) + `MeetingSummaryView` — good. AudioPen's
  **tone/style** and Plaud's **templates** are a future differentiator, not v1.

## Conversational AI: stream it

- Streaming makes responses feel **40–60% faster** at identical total latency;
  target **TTFT < 800 ms**; show a typing indicator, then stream tokens.
- Our chat shows an optimistic message + "thinking" but renders the answer in one
  batch. → Add token streaming (cloud SSE; on-device incremental) so the AI tab
  feels alive. Same applies to surfacing partial summary text.

## Pattern → VoiceScribe action map (feeds `ux-backlog.md`)

| Source pattern | VoiceScribe action | Priority |
|---|---|---|
| Plaud AutoFlow / Granola auto-notes | Auto-summarize after transcription completes (+opt-out pref) | **High** |
| superwhisper trade-off framing | Explain local vs cloud at toggle + onboarding; label engine on results | High |
| Onboarding value slides + contextual priming | Interactive onboarding wizard (Phase 3) | High |
| Streaming chat (40–60% faster perceived) | Stream chat answers; stream/partial summary | Med |
| Notta "no buttons" + clean structured notes | Reduce manual taps across the pipeline; promote most-common action | Med |
| AudioPen tone/style · Plaud templates | Summary tone/template presets | Low (post-v1) |
| Otter action-items front-and-center | Keep summary/action-items one tap from the recording, not buried in a tab | Med |

## Notes / guardrails honored
- Free-tier only; no payments, no paid trials, no card entry. No APK sideloading
  (used web research + store listings, not installs). On-device + free remains the
  default per the project's hard constraint; cloud stays optional.

## Sources
- [Notta vs Fireflies](https://thebusinessdive.com/notta-vs-fireflies) ·
  [Otter vs Notta vs Fireflies vs tl;dv](https://www.umevo.ai/blogs/ume-all-posts/otter-vs-notta-vs-fireflies-vs-tl-dv-the-ultimate-2026-comparison-for-meeting-transcription) ·
  [AI transcription comparison](https://summarizemeeting.com/en/blog/ai-meeting-transcription-comparison)
- [Plaud Intelligence](https://www.plaud.ai/pages/plaud-intelligence) ·
  [Plaud Note](https://www.plaud.ai/products/plaud-note-ai-voice-recorder)
- [AudioPen review](https://10web.io/ai-tools/audiopen/) ·
  [AudioPen (TechCrunch)](https://techcrunch.com/2023/07/03/audio-pen-is-a-great-web-app-for-converting-your-voice-into-text-notes/) ·
  [Letterly](https://play.google.com/store/apps/details?id=com.draftai&hl=en)
- [Granola review (Unite.AI)](https://www.unite.ai/granola-review/) ·
  [Granola vs Fathom](https://www.sybill.ai/blogs/granola-vs-fathom)
- [superwhisper vs MacWhisper (Voibe)](https://www.getvoibe.com/resources/macwhisper-vs-superwhisper/) ·
  [Typeless vs superwhisper](https://www.getvoibe.com/resources/typeless-vs-superwhisper/)
- [Mobile onboarding guide (VWO)](https://vwo.com/blog/mobile-app-onboarding-guide/) ·
  [Permission priming (Appcues)](https://www.appcues.com/blog/mobile-permission-priming) ·
  [Adapty onboarding](https://adapty.io/blog/mobile-app-onboarding/)
- [Streaming AI responses (InstitutePM)](https://www.institutepm.com/knowledge-hub/streaming-ai-responses) ·
  [Streaming UI guide](https://thefrontkit.com/blogs/what-is-streaming-ui-in-ai-applications) ·
  [TTFT latency perception](https://tianpan.co/blog/2026-04-16-streaming-ttft-latency-perception)
