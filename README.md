# VoiceScribe Mobile

Flutter migration of the offline-first VoiceScribe mobile app.

## Stack

- Flutter + Dart
- Riverpod for app state and service injection
- `record` for cross-platform microphone capture
- `whisper_ggml_plus` for on-device whisper.cpp transcription
- JSON persistence behind a repository interface

## App Shape

The app keeps the React Native product flow while using Flutter-native structure:

- Recording: model bootstrap, recording controls, chunking, live transcript preview
- Transcript: searchable transcript sessions and chunk detail
- Summary: UI-ready local/cloud summary controls
- History: searchable/sortable session history with delete
- Speaker: UI-ready speaker profile management

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
