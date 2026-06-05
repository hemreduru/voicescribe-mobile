# VoiceScribe — Production-Readiness Assessment & Plan (ultrathink)

> Companion to `plan/plan.md` and the hardening log in the PRs. This is the
> consolidated production-readiness picture: what is done, what gates a release,
> who must do each remaining step, the deploy runbook, and the risk register.

**Verdict:** The **hardening scope is code-complete and verified** (mobile 52/52 tests,
`flutter analyze` clean, debug APK builds; backend `php -l` clean, `migrate --pretend` valid).
The app is **not yet shippable to production** — a small set of **release gates** remain, most of
which require the user's environment (live DB, signing keystore, a device) and a few product
decisions. None are blocked on further hardening code.

---

## 1. The five goal pillars — status

| Pillar | Status | Evidence / remaining |
|---|---|---|
| **2. Zero data loss + logical sync + light storage** | ✅ code-complete, verified | clearCache synced-only; merge-policy-gated server fetch; cross-user match fix; unique `(user_id, client_local_id)`; resumable pull cursor; synced-chunk audio eviction; +tests. **Remaining:** apply migrations (P0-DB), on-device E2E sync run (P1). |
| **3. Flow bug hunt** | ✅ 7 real bugs fixed | cross-user match, offline connectivity guard, startup hang, merge bypass, settings duplicate label, double refresh, + 2 code-review fixes (overlap-from-trimmed-audio, POST_NOTIFICATIONS). **Remaining:** device smoke test of record→sync→delete loop. |
| **5. Backend cleanup** | ✅ code-complete | spatie removed (trait/config), drop migration for 5 spatie tables + `supabase_user_id`; framework tables kept (drivers use `database`). **Remaining:** run `migrate` + `composer remove` (P0-DB). |
| **4. Whisper best feasible perf** | 🟡 code-complete, unvalidated | threads 3-4 on capable tiers, `Auto/TR/EN` language, `small` unlock (storage-gated), trailing-silence trim. **Remaining:** on-device latency/quality/thermal benchmark (P1). |
| **1. Fluid UI** | 🟡 substantially done | haptics, i18n, fast startup, settings fix, language UI, pending-sync count, transcript-list skeleton, fade transitions. **Remaining (P2):** model-download skeleton, recording-list skeleton, empty-state illustrations, accessibility (TalkBack) pass. |

---

## 2. Release-gating checklist (beyond the 5 pillars)

Legend: **✅ done** · **🔧 user-run (env/device)** · **⚠️ decision/work needed before launch**

### P0 — blockers (must fix before any production release)
- 🔧 **Apply DB migrations** on the real DB: `php artisan migrate` (unique constraints + spatie/supabase drop). Validated via `--pretend`; live migrate is denied from CI. **Back up the DB first.**
- 🔧 **`composer remove spatie/laravel-permission`** (package now unused).
- ⚠️ **Android release signing** — `android/app/build.gradle:36` ships release builds with the **debug** signing config. Create a release keystore + `key.properties` and wire a real `signingConfigs.release`. Play Store rejects debug-signed builds and debug-signed apps are debuggable.
- ⚠️ **Disable cleartext traffic** — `AndroidManifest.xml` sets `android:usesCleartextTraffic="true"`. Set to `false` (or a scoped `network_security_config`) and ensure the API base URL is **HTTPS** in prod `.env`.
- ⚠️ **Production env hardening** (backend `.env`): `APP_DEBUG=false`, `APP_ENV=production`, **unset `AUTH_PASSWORD_BYPASS`** (the login password bypass is hard-gated against prod, but keep the env clean), strong `APP_KEY`, real mail/queue/cache creds.

### P1 — strongly recommended before launch
- ⚠️ **Crash/error reporting** — there is **no** remote crash reporting (no Sentry/Crashlytics). `main.dart` already funnels `FlutterError.onError` + `PlatformDispatcher.onError` into Talker (local). Add a remote sink (Sentry or Firebase Crashlytics) so field crashes are visible.
- ⚠️ **Auth token lifecycle** — Sanctum tokens currently **never expire** and there is no refresh (`config/sanctum.php` expiration is null; `AuthController.buildSessionPayload` returns null refresh/expiry). A leaked token = permanent access. Decide: set `sanctum.expiration` + add a refresh/rotation flow, and a mobile 401→re-login path (`transcript_api_client`/`sync_http_client` already expose `isUnauthorized`).
- 🔧 **Run backend feature tests** — `apt install php8.4-sqlite3 && php artisan test` (the new cross-user + idempotency tests can't run here: no `pdo_sqlite.so` for PHP 8.4).
- 🔧 **On-device validation** — record a mixed EN/TR session; verify model quality/latency for `base` and (on a capable device) `small`; confirm trailing-silence trim doesn't clip word endings; background the app mid-recording and confirm capture continues with a visible notification; verify POST_NOTIFICATIONS prompt on Android 13+.
- ⚠️ **`targetSdkVersion`** — confirm Flutter's default resolves to **34+** (Play requirement); pin explicitly if needed.
- ⚠️ **Privacy** — voice is sensitive personal data. Add a privacy policy + Play Store data-safety form (mic + audio), state on-device processing, and define a retention policy (the app already hard-deletes synced local data; document server-side retention).

### P2 — polish / post-launch
- ⚠️ Model-download skeleton + recording-list skeleton; empty-state illustrations.
- ⚠️ Accessibility pass (TalkBack labels, dynamic font scaling, dark-mode contrast).
- ⚠️ `integration_test/` E2E covering record→transcribe→sync→cleanup.
- ⚠️ Backend rate-limiting on `/auth/login` + `/auth/register`; structured request logging.
- ⚠️ Battery/thermal profiling for long background recordings; model-download on metered networks.

---

## 3. Deploy runbook (order matters)

```bash
# 1. Backend — on the server, in a maintenance window, BACK UP THE DB FIRST
cd /var/www/vsbackend
mysqldump -u <user> -p vsbackend > backup-$(date +%F).sql      # safety
git checkout harden/data-safety-sync                            # or after PR #8 merges, main
composer install --no-dev --optimize-autoloader
php artisan migrate                                            # 2 new migrations
composer remove spatie/laravel-permission
# verify prod .env: APP_DEBUG=false, APP_ENV=production, AUTH_PASSWORD_BYPASS unset, HTTPS API URL
php artisan config:cache && php artisan route:cache
sudo apt install php8.4-sqlite3 && php artisan test            # optional: run feature tests

# 2. Mobile — after backend is live
cd /var/www/voicescribe-mobile
# wire a release keystore + signingConfigs.release; set usesCleartextTraffic=false; HTTPS API base
flutter build apk --release      # or appbundle for Play
# install on a device and run the on-device validation checklist (P1)
```

**Rollback:** both new backend migrations have `down()` (spatie tables are recreated via
`composer require spatie/laravel-permission` + `vendor:publish` + `migrate`). Restore the DB
dump if needed. Mobile: keep the previous signed build for staged rollout / halt.

---

## 4. Risk register

| Risk | Likelihood | Impact | Mitigation (status) |
|---|---|---|---|
| Migration fails on prod data (dup `client_local_id`) | Low | High | `--pretend` valid + 0 dup rows in dev; **back up before migrate**; `down()` available |
| `small` model OOM on a mid device | Low-Med | Med | Storage/tier gate rejects too-heavy models; default stays `base`; **device test (P1)** |
| Silence trim clips a word ending | Low | Med | 250 ms guard + 1 s min-keep; overlap now from trimmed audio; **device audio check (P1)** |
| Background recording killed by OEM battery saver | Med | Med | Foreground service + ongoing notification; document "disable battery optimization" hint |
| Leaked token never expires | Med | High | **P1 decision**: add Sanctum expiry + refresh |
| Field crash invisible (no remote reporting) | High | Med | **P1**: add Sentry/Crashlytics |
| Cleartext/debug-signed release ships | — | High | **P0**: release signing + cleartext off before build |

---

## 5. What was delivered in this hardening pass (for the PR reviewers)

- **Mobile PR #23** — data-safety + sync correctness + Whisper (threads/language/model/silence) + UX
  (haptics/i18n/skeleton/transitions/pending-count) + reliability fixes. 52/52 tests, analyze clean,
  debug APK builds.
- **Backend PR #8** — sync idempotency (unique constraints), cross-user match fix, resumable cursor,
  auth-bypass hardening, spatie/supabase removal, + regression tests. `php -l` clean, `migrate
  --pretend` valid.

Everything implementable and verifiable inside a headless CI box is done. The remaining gates are
deploy actions (DB/keystore/env), one or two security decisions (token lifecycle, crash reporting),
and on-device validation — all owned by the operator, none blocked on further hardening code.
