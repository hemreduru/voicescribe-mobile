import 'dart:async';
import 'dart:io';

import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

// Model bootstrap needs file metadata checks and cleanup around downloaded
// assets. These calls run outside frame-critical UI paths.
// ignore_for_file: avoid_slow_async_io

const _minimumUsableModelBytes = 1024 * 1024;

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

class TranscriptionSegment {
  const TranscriptionSegment({
    required this.startSeconds,
    required this.endSeconds,
    required this.text,
  });

  final double startSeconds;
  final double endSeconds;
  final String text;
}

class TranscriptionResult {
  const TranscriptionResult({required this.text, required this.segments});

  final String text;
  final List<TranscriptionSegment> segments;
}

enum DevicePerformanceTier { entry, balanced, performance, premium }

class DevicePerformanceProfile {
  const DevicePerformanceProfile({
    required this.cpuCores,
    required this.memoryBytes,
    required this.tier,
  });

  final int cpuCores;
  final int? memoryBytes;
  final DevicePerformanceTier tier;
}

enum TranscriptionModelCompatibility { recommended, supported, limited }

class TranscriptionModelCatalogEntry {
  const TranscriptionModelCatalogEntry({
    required this.model,
    required this.compatibility,
    required this.isRecommended,
    required this.totalBytes,
    required this.localBytes,
  });

  final WhisperModel model;
  final TranscriptionModelCompatibility compatibility;
  final bool isRecommended;
  final int? totalBytes;
  final int localBytes;

  int? get remainingBytes {
    final total = totalBytes;
    if (total == null) {
      return null;
    }
    final remaining = total - localBytes;
    return remaining > 0 ? remaining : 0;
  }

  bool get isDownloaded => localBytes >= _minimumUsableModelBytes;
}

abstract class TranscriptionService {
  Stream<ModelDownloadProgress> get downloadProgress;

  WhisperModel get currentModel;
  String get currentModelKey;

  Future<void> selectModel(WhisperModel model);
  Future<DevicePerformanceProfile> resolveDeviceProfile();
  Future<List<TranscriptionModelCatalogEntry>> listModelCatalog();

  Future<WhisperBootstrapResult> ensureModel();
  Future<TranscriptionResult> transcribeChunk(
    String audioPath, {
    double? audioLevel,
  });
  Future<void> dispose();
}

class _TranscriptionRequest {
  const _TranscriptionRequest({
    required this.audioPath,
    required this.completer,
    this.audioLevel,
  });

  final String audioPath;
  final Completer<TranscriptionResult> completer;
  final double? audioLevel;
}

class WhisperTranscriptionService implements TranscriptionService {
  WhisperTranscriptionService({WhisperController? controller})
    : _controller = controller ?? WhisperController(),
      _model = WhisperModel.base;

  final WhisperController _controller;
  final WhisperModel _model;
  final _progressController =
      StreamController<ModelDownloadProgress>.broadcast();
  final Map<WhisperModel, int?> _remoteSizeCache = {};
  DevicePerformanceProfile? _deviceProfile;

  // Sequential transcription queue
  final List<_TranscriptionRequest> _pendingRequests = [];
  bool _isProcessingQueue = false;
  int _consecutiveFailures = 0;

  @override
  Stream<ModelDownloadProgress> get downloadProgress =>
      _progressController.stream;

  @override
  WhisperModel get currentModel => _model;

  @override
  String get currentModelKey => modelKeyFromWhisperModel(_model);

  @override
  Future<void> selectModel(WhisperModel model) async {
    // Model selection is locked to base for stability on mobile devices.
    // Parameter is ignored; only base model is used.
    await _controller.initModel(_model);
  }

  @override
  Future<DevicePerformanceProfile> resolveDeviceProfile() async {
    final cached = _deviceProfile;
    if (cached != null) {
      return cached;
    }

    final cpuCores = Platform.numberOfProcessors;
    final memoryBytes = await _readTotalMemoryBytes();
    final tier = _resolveTier(cpuCores: cpuCores, memoryBytes: memoryBytes);
    final profile = DevicePerformanceProfile(
      cpuCores: cpuCores,
      memoryBytes: memoryBytes,
      tier: tier,
    );
    _deviceProfile = profile;
    return profile;
  }

  @override
  Future<List<TranscriptionModelCatalogEntry>> listModelCatalog() async {
    final profile = await resolveDeviceProfile();
    final recommendedModel = recommendedModelForTier(profile.tier);

    final entries = await Future.wait(
      _supportedCatalogModels.map((model) async {
        final localBytes = await _localBytesForModel(model);
        final totalBytes = await _resolveRemoteModelBytes(model);
        final compatibility = _resolveCompatibility(
          model: model,
          recommendedModel: recommendedModel,
          deviceTier: profile.tier,
        );
        return TranscriptionModelCatalogEntry(
          model: model,
          compatibility: compatibility,
          isRecommended: model == recommendedModel,
          totalBytes: totalBytes,
          localBytes: localBytes,
        );
      }),
    );

    return entries;
  }

  @override
  Future<WhisperBootstrapResult> ensureModel() async {
    final selectedModel = _model;
    final modelPath = await _controller.getPath(selectedModel);
    final file = File(modelPath);
    var downloaded = false;

    if (!await _isUsableModel(file)) {
      await _downloadModel(model: selectedModel, outputFile: file);
      downloaded = true;
    }

    await _controller.initModel(selectedModel);
    return WhisperBootstrapResult(
      path: modelPath,
      downloaded: downloaded,
      loaded: true,
    );
  }

  @override
  Future<TranscriptionResult> transcribeChunk(
    String audioPath, {
    double? audioLevel,
  }) async {
    final completer = Completer<TranscriptionResult>();
    _pendingRequests.add(
      _TranscriptionRequest(
        audioPath: audioPath,
        completer: completer,
        audioLevel: audioLevel,
      ),
    );
    unawaited(_processQueue());
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _pendingRequests.isEmpty) {
      return;
    }
    _isProcessingQueue = true;

    try {
      while (_pendingRequests.isNotEmpty) {
        final request = _pendingRequests.removeAt(0);
        try {
          final result = await _executeWithRetry(
            request.audioPath,
            audioLevel: request.audioLevel,
          );
          _consecutiveFailures = 0;
          if (!request.completer.isCompleted) {
            request.completer.complete(result);
          }
        } catch (error, stackTrace) {
          _consecutiveFailures++;
          // Only re-init after several consecutive failures — re-initing on
          // every error masks transient issues and can wedge the queue if
          // initModel itself hangs.
          if (_consecutiveFailures >= 3) {
            AppLogger.info(
              '[Transcription] $_consecutiveFailures consecutive failure(s), '
              're-initializing model',
            );
            try {
              await _controller
                  .initModel(_model)
                  .timeout(const Duration(seconds: 15));
              _consecutiveFailures = 0;
            } catch (initError) {
              AppLogger.warning(
                '[Transcription] Model re-initialization failed: $initError',
              );
            }
          }
          if (!request.completer.isCompleted) {
            request.completer.completeError(error, stackTrace);
          }
        }
      }
    } finally {
      _isProcessingQueue = false;
      // If new requests landed while we were exiting, kick the pump again.
      if (_pendingRequests.isNotEmpty) {
        unawaited(_processQueue());
      }
    }
  }

  static const double _silenceThreshold = 0.035;

  Future<TranscriptionResult> _executeWithRetry(
    String audioPath, {
    double? audioLevel,
  }) async {
    final selectedModel = _model;
    final threads = await _resolveThreads();
    final chunkId = _chunkIdFromPath(audioPath);
    const maxAttempts = 2;

    AppLogger.info(
      '[Transcription] Starting chunk: $chunkId | '
      'model: ${selectedModel.modelName} | threads: $threads | '
      'audioLevel: $audioLevel',
    );

    Exception? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await _executeSingle(
          audioPath: audioPath,
          model: selectedModel,
          threads: threads,
          attempt: attempt,
        );
        if (result.text.trim().isEmpty) {
          if (audioLevel == null || audioLevel < _silenceThreshold) {
            AppLogger.info(
              '[Transcription] Silent chunk detected for chunk: $chunkId'
              '${audioLevel == null ? ' (audioLevel unknown)' : ''}',
            );
            return result;
          }
          throw const TranscriptionEmptyException(
            'Transcription returned empty text for a non-silent chunk.',
          );
        }
        AppLogger.info('[Transcription] Completed chunk: $chunkId');
        return result;
      } catch (error) {
        lastError = error as Exception;
        if (attempt < maxAttempts) {
          AppLogger.warning(
            '[Transcription] Attempt $attempt failed for chunk: $chunkId | '
            'error: $error. Retrying (${attempt + 1}/$maxAttempts)...',
          );
        } else {
          AppLogger.error(
            '[Transcription] All $maxAttempts attempts failed for chunk: $chunkId',
            error,
          );
        }
      }
    }

    throw lastError!;
  }

  Future<TranscriptionResult> _executeSingle({
    required String audioPath,
    required WhisperModel model,
    required int threads,
    required int attempt,
  }) async {
    final timeoutDuration = await _resolveTimeout();

    final future = _controller.transcribe(
      model: model,
      audioPath: audioPath,
      lang: 'auto',
      convert: false,
      threads: threads,
    );

    final result = await future.timeout(
      timeoutDuration,
      onTimeout: () => throw TimeoutException(
        'Transcription timed out after ${timeoutDuration.inSeconds}s '
        '(attempt $attempt)',
      ),
    );

    final transcription = result?.transcription;
    final segments = (transcription?.segments ?? const [])
        .map(
          (segment) => TranscriptionSegment(
            startSeconds: segment.fromTs.inMicroseconds / 1000000,
            endSeconds: segment.toTs.inMicroseconds / 1000000,
            text: segment.text.trim(),
          ),
        )
        .where(
          (segment) =>
              segment.endSeconds >= segment.startSeconds &&
              segment.text.isNotEmpty,
        )
        .toList();
    return TranscriptionResult(
      text: transcription?.text.trim() ?? '',
      segments: segments,
    );
  }

  Future<Duration> _resolveTimeout() async {
    final profile = await resolveDeviceProfile();
    return switch (profile.tier) {
      DevicePerformanceTier.entry => const Duration(seconds: 45),
      DevicePerformanceTier.balanced => const Duration(seconds: 30),
      DevicePerformanceTier.performance => const Duration(seconds: 20),
      DevicePerformanceTier.premium => const Duration(seconds: 20),
    };
  }

  Future<int> _resolveThreads() async {
    final profile = await resolveDeviceProfile();
    return switch (profile.tier) {
      DevicePerformanceTier.entry => 1,
      DevicePerformanceTier.balanced => 2,
      DevicePerformanceTier.performance => 2,
      DevicePerformanceTier.premium => 2,
    };
  }

  String _chunkIdFromPath(String audioPath) {
    try {
      return audioPath.split('/').last;
    } catch (_) {
      return audioPath;
    }
  }

  @override
  Future<void> dispose() async {
    for (final request in _pendingRequests) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(
          StateError('TranscriptionService disposed'),
        );
      }
    }
    _pendingRequests.clear();
    await _controller.dispose(model: _model);
    await _progressController.close();
  }

  Future<bool> _isUsableModel(File file) async {
    if (!await file.exists()) {
      return false;
    }
    final length = await file.length();
    return length >= _minimumUsableModelBytes;
  }

  Future<void> _downloadModel({
    required WhisperModel model,
    required File outputFile,
  }) async {
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

  Future<int?> _resolveRemoteModelBytes(WhisperModel model) async {
    final cached = _remoteSizeCache[model];
    if (cached != null) {
      return cached;
    }

    final resolved = await _probeRemoteModelBytes(model);
    if (resolved != null) {
      _remoteSizeCache[model] = resolved;
      return resolved;
    }

    final fallback = _metadataByModel[model]?.fallbackSizeBytes;
    _remoteSizeCache[model] = fallback;
    return fallback;
  }

  Future<int?> _probeRemoteModelBytes(WhisperModel model) async {
    final client = HttpClient();
    try {
      final request = await client
          .openUrl('HEAD', model.modelUri)
          .timeout(const Duration(seconds: 4));
      request.followRedirects = true;
      request.maxRedirects = 5;
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'VoiceScribe-Flutter/1.0',
      );

      final response = await request.close().timeout(
        const Duration(seconds: 6),
      );
      final statusCode = response.statusCode;
      final contentLength = response.contentLength;
      await response.drain<void>();

      if (statusCode >= 200 && statusCode < 400 && contentLength > 0) {
        return contentLength;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<int> _localBytesForModel(WhisperModel model) async {
    final path = await _controller.getPath(model);
    final file = File(path);
    if (!await file.exists()) {
      return 0;
    }
    return file.length();
  }

  Future<int?> _readTotalMemoryBytes() async {
    if (!Platform.isAndroid && !Platform.isLinux) {
      return null;
    }

    final memInfo = File('/proc/meminfo');
    if (!await memInfo.exists()) {
      return null;
    }

    try {
      final lines = await memInfo.readAsLines();
      final memTotalLine = lines.firstWhere(
        (line) => line.startsWith('MemTotal:'),
        orElse: () => '',
      );
      if (memTotalLine.isEmpty) {
        return null;
      }
      final match = RegExp(r'(\d+)').firstMatch(memTotalLine);
      final kb = int.tryParse(match?.group(1) ?? '');
      if (kb == null || kb <= 0) {
        return null;
      }
      return kb * 1024;
    } catch (_) {
      return null;
    }
  }

  DevicePerformanceTier _resolveTier({
    required int cpuCores,
    required int? memoryBytes,
  }) {
    final ramGiB = memoryBytes == null
        ? null
        : memoryBytes / (1024 * 1024 * 1024);

    if (ramGiB != null) {
      if (ramGiB >= 8 && cpuCores >= 8) {
        return DevicePerformanceTier.premium;
      }
      if (ramGiB >= 6 && cpuCores >= 6) {
        return DevicePerformanceTier.performance;
      }
      if (ramGiB >= 4 && cpuCores >= 4) {
        return DevicePerformanceTier.balanced;
      }
      return DevicePerformanceTier.entry;
    }

    if (cpuCores >= 8) {
      return DevicePerformanceTier.performance;
    }
    if (cpuCores >= 6) {
      return DevicePerformanceTier.balanced;
    }
    return DevicePerformanceTier.entry;
  }

  TranscriptionModelCompatibility _resolveCompatibility({
    required WhisperModel model,
    required WhisperModel recommendedModel,
    required DevicePerformanceTier deviceTier,
  }) {
    if (model == recommendedModel) {
      return TranscriptionModelCompatibility.recommended;
    }

    final requiredTier =
        _metadataByModel[model]?.minimumTier ?? DevicePerformanceTier.entry;
    if (_tierRank(deviceTier) >= _tierRank(requiredTier)) {
      return TranscriptionModelCompatibility.supported;
    }
    return TranscriptionModelCompatibility.limited;
  }

  int _tierRank(DevicePerformanceTier tier) {
    return switch (tier) {
      DevicePerformanceTier.entry => 0,
      DevicePerformanceTier.balanced => 1,
      DevicePerformanceTier.performance => 2,
      DevicePerformanceTier.premium => 3,
    };
  }
}

WhisperModel whisperModelFromKey(String value) {
  return switch (AppPreferences.normalizeTranscriptionModel(value)) {
    'tiny' => WhisperModel.tiny,
    'base' => WhisperModel.base,
    'small' => WhisperModel.small,
    'medium' => WhisperModel.medium,
    'large-v3' => WhisperModel.large,
    'large-v3-turbo' => WhisperModel.largeV3Turbo,
    _ => WhisperModel.base,
  };
}

String modelKeyFromWhisperModel(WhisperModel model) {
  return model.modelName;
}

WhisperModel recommendedModelForTier(DevicePerformanceTier tier) {
  // Cap recommendation at small to avoid heavy models on mobile devices.
  return switch (tier) {
    DevicePerformanceTier.entry => WhisperModel.tiny,
    DevicePerformanceTier.balanced => WhisperModel.base,
    DevicePerformanceTier.performance => WhisperModel.small,
    DevicePerformanceTier.premium => WhisperModel.small,
  };
}

class _ModelMetadata {
  const _ModelMetadata({
    required this.minimumTier,
    required this.fallbackSizeBytes,
  });

  final DevicePerformanceTier minimumTier;
  final int fallbackSizeBytes;
}

const _mb = 1024 * 1024;

const List<WhisperModel> _supportedCatalogModels = <WhisperModel>[
  WhisperModel.tiny,
  WhisperModel.base,
  WhisperModel.small,
  WhisperModel.medium,
  WhisperModel.large,
  WhisperModel.largeV3Turbo,
];

class TranscriptionEmptyException implements Exception {
  const TranscriptionEmptyException(this.message);

  final String message;

  @override
  String toString() => 'TranscriptionEmptyException: $message';
}

const Map<WhisperModel, _ModelMetadata> _metadataByModel = {
  WhisperModel.tiny: _ModelMetadata(
    minimumTier: DevicePerformanceTier.entry,
    fallbackSizeBytes: 75 * _mb,
  ),
  WhisperModel.base: _ModelMetadata(
    minimumTier: DevicePerformanceTier.balanced,
    fallbackSizeBytes: 142 * _mb,
  ),
  WhisperModel.small: _ModelMetadata(
    minimumTier: DevicePerformanceTier.performance,
    fallbackSizeBytes: 466 * _mb,
  ),
  WhisperModel.medium: _ModelMetadata(
    minimumTier: DevicePerformanceTier.premium,
    fallbackSizeBytes: 1530 * _mb,
  ),
  WhisperModel.large: _ModelMetadata(
    minimumTier: DevicePerformanceTier.premium,
    fallbackSizeBytes: 3020 * _mb,
  ),
  WhisperModel.largeV3Turbo: _ModelMetadata(
    minimumTier: DevicePerformanceTier.premium,
    fallbackSizeBytes: 1620 * _mb,
  ),
};
