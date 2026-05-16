# VoiceScribe Mobile

Flutter migration of the offline-first VoiceScribe mobile app.

## Stack

- Flutter + Dart
- flutter_bloc for feature state and repository injection
- `record` for cross-platform microphone capture
- `whisper_ggml_plus` for on-device whisper.cpp transcription
- SQLite persistence behind repository interfaces

## App Shape

The app keeps the VoiceScribe product flow while using Flutter-native structure:

- Recording: model bootstrap, recording controls, chunking, live transcript preview
- Transcript: searchable transcript sessions and chunk detail
- Summary: local/cloud summary controls
- Settings: account, summary, theme, language, and model status controls

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The Whisper base model is downloaded on first launch into app-writable storage. iOS
builds require macOS/Xcode; this Linux workspace can validate Dart and Android
builds only.
