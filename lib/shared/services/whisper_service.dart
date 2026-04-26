import 'dart:async';
import 'dart:io';

import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

class ModelDownloadProgress {
  const ModelDownloadProgress({
    required this.bytesDownloaded,
    required this.totalBytes,
  });

  final int bytesDownloaded;
  final int? totalBytes;

  double? get percent {
    final total = totalBytes;
    if (total == null || total <= 0) {
      return null;
    }
    return (bytesDownloaded / total * 100).clamp(0, 100);
  }
}

class WhisperBootstrapResult {
  const WhisperBootstrapResult({
    required this.path,
    required this.downloaded,
    required this.loaded,
  });

  final String path;
  final bool downloaded;
  final bool loaded;
}

class WhisperTranscriptionService {
  WhisperTranscriptionService({
    WhisperController? controller,
    this.model = WhisperModel.base,
  }) : _controller = controller ?? WhisperController();

  final WhisperController _controller;
  final WhisperModel model;
  final _progressController =
      StreamController<ModelDownloadProgress>.broadcast();

  Stream<ModelDownloadProgress> get downloadProgress =>
      _progressController.stream;

  Future<WhisperBootstrapResult> ensureModel() async {
    final modelPath = await _controller.getPath(model);
    final file = File(modelPath);
    var downloaded = false;

    if (!await _isUsableModel(file)) {
      await _downloadModel(file);
      downloaded = true;
    }

    await _controller.initModel(model);
    return WhisperBootstrapResult(
      path: modelPath,
      downloaded: downloaded,
      loaded: true,
    );
  }

  Future<String> transcribeChunk(String audioPath) async {
    final result = await _controller.transcribe(
      model: model,
      audioPath: audioPath,
      lang: 'auto',
      withTimestamps: false,
      convert: false,
      threads: 4,
      vadMode: WhisperVadMode.auto,
    );
    return result?.transcription.text.trim() ?? '';
  }

  Future<void> dispose() async {
    await _controller.dispose(model: model);
    await _progressController.close();
  }

  Future<bool> _isUsableModel(File file) async {
    if (!await file.exists()) {
      return false;
    }
    final length = await file.length();
    return length >= 1024 * 1024;
  }

  Future<void> _downloadModel(File outputFile) async {
    final tempFile = File('${outputFile.path}.part');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    await outputFile.parent.create(recursive: true);

    final client = HttpClient();
    try {
      final request = await client.getUrl(model.modelUri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'VoiceScribe-Flutter/1.0',
      );
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode > 299) {
        throw HttpException(
          'Model download failed: HTTP ${response.statusCode}',
          uri: model.modelUri,
        );
      }

      final totalBytes = response.contentLength > 0
          ? response.contentLength
          : null;
      var downloadedBytes = 0;
      final sink = tempFile.openWrite();
      try {
        await for (final chunk in response) {
          downloadedBytes += chunk.length;
          sink.add(chunk);
          _progressController.add(
            ModelDownloadProgress(
              bytesDownloaded: downloadedBytes,
              totalBytes: totalBytes,
            ),
          );
        }
      } finally {
        await sink.close();
      }

      if (totalBytes != null && await tempFile.length() != totalBytes) {
        throw const FileSystemException('Downloaded model size mismatch');
      }
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      await tempFile.rename(outputFile.path);
      _progressController.add(
        ModelDownloadProgress(
          bytesDownloaded: await outputFile.length(),
          totalBytes: totalBytes ?? await outputFile.length(),
        ),
      );
    } finally {
      client.close(force: true);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
}
