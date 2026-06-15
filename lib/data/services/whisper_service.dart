import 'dart:async';
import 'dart:io';

import 'package:voicescribe_mobile/data/services/transcription/transcription_estimator.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

// 16 kHz mono 16-bit PCM = 32000 bytes per second of audio, plus a 44-byte WAV
// header. Used to derive a chunk's audio length from its file size for ETA.
const int _wavBytesPerSecond = 16000 * 1 * 2;
const int _wavHeaderBytes = 44;

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

  /// Measured processing-seconds-per-audio-second for the current model on this
  /// device. Refines as chunks complete; seeded with a per-model default so the
  /// first estimate is still reasonable. See [TranscriptionEstimator].
  double get currentRealtimeFactor;

  /// Estimated wall-clock time to transcribe [pendingAudioSeconds] of queued
  /// audio with the current model on this device.
  Duration estimateBacklog(double pendingAudioSeconds);

  /// Sets the transcription language: `auto` (detect per window, best for
  /// bilingual/code-switching audio), or an ISO code like `tr`/`en`.
  void setTranscriptionLanguage(String language);

  /// The language the next transcription will use (`auto`/`tr`/`en`).
  String get currentTranscriptionLanguage;

  Future<void> selectModel(WhisperModel model);
  Future<DevicePerformanceProfile> resolveDeviceProfile();
  Future<List<TranscriptionModelCatalogEntry>> listModelCatalog();

  Future<WhisperBootstrapResult> ensureModel();

  /// Like [ensureModel] but keeps startup non-blocking: if the desired model
  /// isn't downloaded yet while another model already is, it activates the
  /// downloaded one instead of blocking the app on a large download.
  Future<WhisperBootstrapResult> ensureUsableModel();
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
      _model = WhisperModel.base,
      _desiredModel = WhisperModel.base;

  final WhisperController _controller;
  // Defaults to `base` (the safe choice for low-end devices). Capable devices
  // may opt into a heavier model via [selectModel]; models that exceed the
  // device tier are rejected so we never OOM an entry-level phone.
  //
  // [_model] is the *active* model: the one whose file is present on disk and
  // currently driving transcription. [_desiredModel] is the user's requested
  // target; it only becomes active inside [ensureModel] once its file is fully
  // downloaded. Keeping these separate is what prevents the queue from running
  // against a half-downloaded model file when the user switches mid-recording.
  WhisperModel _model;
  WhisperModel _desiredModel;
  // `auto` lets Whisper detect the language per 30s window, which is the right
  // default for bilingual (e.g. EN/TR) meetings; `tr`/`en` force one language.
  String _language = 'auto';
  final _progressController =
      StreamController<ModelDownloadProgress>.broadcast();
  final Map<WhisperModel, int?> _remoteSizeCache = {};
  DevicePerformanceProfile? _deviceProfile;

  // Learns this device's transcription speed (per model) to drive live ETAs.
  final TranscriptionEstimator _estimator = TranscriptionEstimator();

  // Sequential transcription queue
  final List<_TranscriptionRequest> _pendingRequests = [];
  bool _isProcessingQueue = false;
  int _consecutiveFailures = 0;

  // Serializes every native-controller touch (transcribe, model promote,
  // re-init, dispose) so a model switch can never interleave with an in-flight
  // transcription. The long download in [ensureModel] runs *outside* this lock,
  // so transcription keeps flowing on the current model while the next one
  // downloads; only the instant promote step takes the lock.
  Future<void> _controllerLock = Future<void>.value();

  static const Duration _transcribeTimeout = Duration(seconds: 240);

  @override
  Stream<ModelDownloadProgress> get downloadProgress =>
      _progressController.stream;

  @override
  WhisperModel get currentModel => _model;

  @override
  String get currentModelKey => modelKeyFromWhisperModel(_model);

  @override
  double get currentRealtimeFactor => _estimator.factorFor(currentModelKey);

  @override
  Duration estimateBacklog(double pendingAudioSeconds) =>
      _estimator.estimateFor(
        modelKey: currentModelKey,
        pendingAudioSeconds: pendingAudioSeconds,
      );

  @override
  void setTranscriptionLanguage(String language) {
    final normalized = AppPreferences.normalizeTranscriptionLanguage(language);
    if (normalized == _language) {
      return;
    }
    _language = normalized;
    AppLogger.info('[Transcription] Language set to $_language');
  }

  @override
  String get currentTranscriptionLanguage => _language;

  @override
  Future<void> selectModel(WhisperModel model) async {
    // Only records the *desired* target. The active model is not switched here:
    // it flips in [ensureModel] once the target's file is fully downloaded, so
    // the transcription queue is never pointed at a missing/partial model file.
    if (model == _desiredModel) {
      return;
    }
    if (await isModelAllowedForDevice(model)) {
      _desiredModel = model;
      AppLogger.info('[Transcription] Desired model set to ${model.modelName}');
    } else {
      AppLogger.info(
        '[Transcription] selectModel(${model.modelName}) rejected — '
        'exceeds device capability; staying on ${_desiredModel.modelName}',
      );
    }
  }

  /// A model is allowed when it is at most as heavy as what the device tier can
  /// reasonably run (i.e. not flagged `limited` by the catalog logic). This is
  /// the storage/OOM gate that keeps heavy models off entry-level phones.
  Future<bool> isModelAllowedForDevice(WhisperModel model) async {
    final profile = await resolveDeviceProfile();
    final compatibility = _resolveCompatibility(
      model: model,
      recommendedModel: recommendedModelForTier(profile.tier),
      deviceTier: profile.tier,
    );
    return compatibility != TranscriptionModelCompatibility.limited;
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
    final target = _desiredModel;
    final modelPath = await _controller.getPath(target);
    final file = File(modelPath);
    var downloaded = false;

    // Download (the slow part) runs without the controller lock, so any
    // in-flight transcription keeps running on the current model meanwhile.
    if (!await _isUsableModel(file)) {
      await _downloadModel(model: target, outputFile: file);
      downloaded = true;
    }

    // Promote atomically: take the lock so the active model only flips between
    // chunks, never mid-transcribe. The file is guaranteed present by now.
    await _runExclusive(() async {
      _model = target;
      await _controller.initModel(target);
    });
    return WhisperBootstrapResult(
      path: modelPath,
      downloaded: downloaded,
      loaded: true,
    );
  }

  @override
  Future<WhisperBootstrapResult> ensureUsableModel() async {
    // If the desired model is already on disk, just promote it.
    if (await _isModelDownloaded(_desiredModel)) {
      return ensureModel();
    }
    // The desired model isn't downloaded (e.g. a previously-interrupted switch
    // left only a `.part`). Rather than block the whole app on a multi-hundred-
    // MB download at every launch, fall back to the best model that *is* already
    // downloaded so the app is immediately usable. The user can re-trigger the
    // heavier download from Settings, where it shows progress and doesn't lock
    // the app. Only a genuine first run (nothing on disk) blocks on a download.
    final fallback = await _bestDownloadedModel();
    if (fallback != null && fallback != _desiredModel) {
      AppLogger.info(
        '[Transcription] Desired model ${_desiredModel.modelName} not '
        'downloaded; activating already-downloaded ${fallback.modelName} to '
        'keep startup non-blocking',
      );
      _desiredModel = fallback;
    }
    return ensureModel();
  }

  Future<bool> _isModelDownloaded(WhisperModel model) async {
    final path = await _controller.getPath(model);
    return _isUsableModel(File(path));
  }

  /// The heaviest already-downloaded model the device is allowed to run, so a
  /// fallback activates the best the user already has — not just the smallest.
  Future<WhisperModel?> _bestDownloadedModel() async {
    const preference = [
      WhisperModel.small,
      WhisperModel.base,
      WhisperModel.tiny,
    ];
    for (final model in preference) {
      if (await _isModelDownloaded(model) &&
          await isModelAllowedForDevice(model)) {
        return model;
      }
    }
    return null;
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

  /// Runs [action] with exclusive access to the native controller. Calls are
  /// chained so they execute one at a time in submission order; a failure in
  /// one call doesn't poison the lock for the next.
  Future<T> _runExclusive<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final previous = _controllerLock;
    _controllerLock = completer.future.then<void>(
      (_) {},
      onError: (_) {},
    );
    previous.whenComplete(() async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
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
              await _runExclusive(
                () => _controller
                    .initModel(_model)
                    .timeout(const Duration(seconds: 15)),
              );
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

    final audioSeconds = await _audioSecondsForWav(audioPath);
    // Object, not Exception: the plugin can throw `Error`s (OOM, StateError)
    // and a failed cast here would mask the real failure with a TypeError.
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final stopwatch = Stopwatch()..start();
        final result = await _executeSingle(
          audioPath: audioPath,
          model: selectedModel,
          threads: threads,
          attempt: attempt,
        );
        stopwatch.stop();
        // Feed the per-device speed estimator so live ETAs reflect this exact
        // hardware/model. Both empty and non-empty results consumed model time
        // proportional to the clip length, so both are representative samples.
        _estimator.record(
          modelKey: modelKeyFromWhisperModel(selectedModel),
          audioSeconds: audioSeconds,
          processing: stopwatch.elapsed,
        );
        if (result.text.trim().isEmpty) {
          AppLogger.info(
            '[Transcription] Empty result for chunk: $chunkId '
            '(audioLevel: ${audioLevel ?? 'unknown'})',
          );
          return result;
        }
        AppLogger.info('[Transcription] Completed chunk: $chunkId');
        return result;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
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

    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }

  Future<TranscriptionResult> _executeSingle({
    required String audioPath,
    required WhisperModel model,
    required int threads,
    required int attempt,
  }) async {
    // Hold the controller lock for the native call so a concurrent model
    // promote/re-init can't swap the model out from under an in-flight clip.
    final result = await _runExclusive(
      () => _controller
          .transcribe(
            model: model,
            audioPath: audioPath,
            lang: _language,
            convert: false,
            threads: threads,
          )
          .timeout(
            _transcribeTimeout,
            onTimeout: () => throw TimeoutException(
              'Transcription timed out after ${_transcribeTimeout.inSeconds}s '
              '(attempt $attempt)',
            ),
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

  Future<int> _resolveThreads() async {
    final profile = await resolveDeviceProfile();
    final cores = profile.cpuCores;
    // Always leave at least one core for the UI/audio-capture threads so the
    // app stays responsive, and cap the count to limit sustained thermal load.
    return switch (profile.tier) {
      DevicePerformanceTier.entry => 1,
      DevicePerformanceTier.balanced => 2,
      DevicePerformanceTier.performance => _clampThreads(cores >= 8 ? 4 : 3),
      DevicePerformanceTier.premium => _clampThreads(4),
    };
  }

  int _clampThreads(int desired) {
    final cores = _deviceProfile?.cpuCores ?? desired;
    final headroom = cores > 1 ? cores - 1 : 1;
    return desired.clamp(1, headroom);
  }

  String _chunkIdFromPath(String audioPath) => audioPath.split('/').last;

  /// Derives a chunk's audio length (seconds) from its WAV file size. Chunks are
  /// always 16 kHz mono 16-bit PCM, so size maps directly to duration. Returns 0
  /// when the file is missing/too small, which the estimator safely ignores.
  Future<double> _audioSecondsForWav(String audioPath) async {
    try {
      final length = await File(audioPath).length();
      final dataBytes = length - _wavHeaderBytes;
      if (dataBytes <= 0) {
        return 0;
      }
      return dataBytes / _wavBytesPerSecond;
    } catch (_) {
      return 0;
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
    await _runExclusive(() => _controller.dispose(model: _model));
    await _progressController.close();
  }

  Future<bool> _isUsableModel(File file) async {
    if (!await file.exists()) {
      return false;
    }
    final length = await file.length();
    return length >= _minimumUsableModelBytes;
  }

  /// Downloads the model with HTTP Range resume: an interrupted attempt keeps
  /// its `.part` file and the next attempt continues from where it stopped —
  /// crucial for the multi-hundred-MB models on mobile networks. A per-chunk
  /// stall timeout ensures a dead connection fails (and is resumable later)
  /// instead of hanging bootstrap forever.
  Future<void> _downloadModel({
    required WhisperModel model,
    required File outputFile,
  }) async {
    const stallTimeout = Duration(seconds: 30);
    final tempFile = File('${outputFile.path}.part');
    await outputFile.parent.create(recursive: true);
    final resumeOffset = await tempFile.exists() ? await tempFile.length() : 0;

    final client = HttpClient();
    var completed = false;
    try {
      final request = await client.getUrl(model.modelUri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'VoiceScribe-Flutter/1.0',
      );
      if (resumeOffset > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$resumeOffset-');
      }
      final response = await request.close().timeout(stallTimeout);

      final resumed =
          resumeOffset > 0 && response.statusCode == HttpStatus.partialContent;
      if (response.statusCode < 200 || response.statusCode > 299) {
        throw HttpException(
          'Model download failed: HTTP ${response.statusCode}',
          uri: model.modelUri,
        );
      }

      final baseOffset = resumed ? resumeOffset : 0;
      final totalBytes = response.contentLength > 0
          ? baseOffset + response.contentLength
          : null;
      var downloadedBytes = baseOffset;
      var lastNotifiedBytes = 0;
      final sink = tempFile.openWrite(
        mode: resumed ? FileMode.append : FileMode.write,
      );
      try {
        // timeout() on the stream fires when no chunk arrives within the
        // window — a stalled transfer, not a slow one.
        await for (final chunk in response.timeout(
          stallTimeout,
          onTimeout: (sink) => sink.addError(
            TimeoutException('Model download stalled', stallTimeout),
          ),
        )) {
          downloadedBytes += chunk.length;
          sink.add(chunk);
          // Throttle progress events: one per ~512 KB instead of one per
          // network packet (thousands of UI rebuilds for a large model).
          if (downloadedBytes - lastNotifiedBytes >= 512 * 1024) {
            lastNotifiedBytes = downloadedBytes;
            _progressController.add(
              ModelDownloadProgress(
                bytesDownloaded: downloadedBytes,
                totalBytes: totalBytes,
              ),
            );
          }
        }
      } finally {
        await sink.close();
      }

      if (totalBytes != null && await tempFile.length() != totalBytes) {
        // Corrupt partial state — discard so the next attempt starts clean.
        await tempFile.delete();
        throw const FileSystemException('Downloaded model size mismatch');
      }
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      await tempFile.rename(outputFile.path);
      completed = true;
      _progressController.add(
        ModelDownloadProgress(
          bytesDownloaded: await outputFile.length(),
          totalBytes: totalBytes ?? await outputFile.length(),
        ),
      );
    } finally {
      client.close(force: true);
      // Keep the .part file on failure — it is the resume point for the next
      // attempt. (A size-mismatch above deletes it explicitly.)
      if (completed && await tempFile.exists()) {
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
    } catch (error) {
      AppLogger.warning(
        '[Transcription] HEAD probe failed for ${model.modelName}: $error',
      );
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
