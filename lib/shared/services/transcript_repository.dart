import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/domain.dart';

abstract class TranscriptRepository {
  Future<PersistedTranscriptState> load();
  Future<void> save(PersistedTranscriptState state);
}

class JsonTranscriptRepository implements TranscriptRepository {
  const JsonTranscriptRepository();

  @override
  Future<PersistedTranscriptState> load() async {
    final file = await _stateFile();
    if (!await file.exists()) {
      return PersistedTranscriptState.empty();
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return PersistedTranscriptState.empty();
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return PersistedTranscriptState.empty();
      }
      return PersistedTranscriptState.fromJson(decoded);
    } catch (_) {
      return PersistedTranscriptState.empty();
    }
  }

  @override
  Future<void> save(PersistedTranscriptState state) async {
    final file = await _stateFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(state.toJson()), flush: true);
  }

  Future<File> _stateFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/state/transcripts.json');
  }
}
