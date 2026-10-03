# VoiceScribe Mobile

Flutter migration of the offline-first VoiceScribe mobile app.

## Stack

- Flutter + Dart
- flutter_bloc for feature state and repository injection
- `record` for cross-platform microphone capture
- Cloud speech-to-text through the backend `POST /api/v1/transcribe` relay
- SQLite persistence behind repository interfaces

## App Shape

The app keeps the VoiceScribe product flow while using Flutter-native structure:

- Recording: recording controls, chunking, live transcript preview
- Transcript: searchable transcript sessions and chunk detail
- Summary: cloud summary and chat
- Settings: account, theme, and language controls

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Backend URL (`API_BASE_URL`)

The backend URL is never hardcoded in Dart code. It is resolved by
`lib/ui/core/utils/env_config.dart` in this order (last one wins):

1. Built-in development default (`http://vsbackend.test`)
2. `.env` file in the project root (copy `.env.example`; local development)
3. `--dart-define=API_BASE_URL=...` (builds and CI)

```bash
# Run against a specific backend
flutter run --dart-define=API_BASE_URL=https://<backend-host>

# Release build (required: release builds refuse to start with a dev host)
flutter build apk --release --dart-define=API_BASE_URL=https://<backend-host>
```

A test backend is currently available for development; production will use
a different domain, so only change `API_BASE_URL`, never the source code.

In CI (`.github/workflows/flutter_ci.yaml`) the value comes from the GitHub
repository variable `API_BASE_URL` (Settings > Secrets and variables >
Actions > Variables).

Transcription, summaries and chat require network access. iOS
builds require macOS/Xcode; this Linux workspace can validate Dart and Android
builds only.
