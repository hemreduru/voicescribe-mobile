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

Transcription, summaries and chat require network access. iOS
builds require macOS/Xcode; this Linux workspace can validate Dart and Android
builds only.
