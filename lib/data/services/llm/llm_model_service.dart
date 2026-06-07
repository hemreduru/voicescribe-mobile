import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:voicescribe_mobile/data/services/transcript_api_client.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart'
    show DevicePerformanceTier, ModelDownloadProgress, TranscriptionService;
import 'package:voicescribe_mobile/ui/core/utils/env_config.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

/// Approximate on-disk size of Gemma 3 1B int8 (~1.0 GB) shown for labels
/// before the real size is fetched from the backend config.
const int _gemma1bFallbackBytes = 1005 * 1024 * 1024;

class LocalLlmModelCatalogEntry {
  const LocalLlmModelCatalogEntry({
    required this.label,
    required this.totalBytes,
    required this.isDownloaded,
    required this.isSupported,
  });

  final String label;
  final int totalBytes;
  final bool isDownloaded;
  final bool isSupported;
}

/// Download config for the on-device model, served by the backend so the gated
/// HuggingFace token is never bundled in the app binary.
class _LocalModelConfig {
  const _LocalModelConfig({
    required this.url,
    required this.token,
    required this.fileName,
    required this.sizeBytes,
    required this.modelType,
    required this.fileType,
    required this.label,
  });

  final String url;
  final String? token;
  final String fileName;
  final int sizeBytes;
  final ModelType modelType;
  final ModelFileType fileType;
  final String label;
}

/// Manages the on-device summarization model (Gemma 3 1B `.task`): device gating,
/// download (with progress), and readiness — mirroring the Whisper model flow.
///
/// The download URL + gated-model token are fetched from the backend
/// (`/api/v1/local-summary-model`); device gating reuses
/// [TranscriptionService.resolveDeviceProfile] so the RAM/core detection logic
/// lives in one place.
class LocalLlmModelService {
  LocalLlmModelService({
    required TranscriptionService transcriptionService,
    required TranscriptApiClient apiClient,
    required String? Function() tokenProvider,
  }) : _transcriptionService = transcriptionService,
       _apiClient = apiClient,
       _tokenProvider = tokenProvider;

  final TranscriptionService _transcriptionService;
  final TranscriptApiClient _apiClient;
  final String? Function() _tokenProvider;
  final StreamController<ModelDownloadProgress> _progress =
      StreamController<ModelDownloadProgress>.broadcast();
  bool _runtimeInitialized = false;
  _LocalModelConfig? _config;

  Stream<ModelDownloadProgress> get downloadProgress => _progress.stream;

  /// Fallback filename derived from the bundled URL, used for the local
  /// "is it downloaded?" check before the backend config has been fetched.
  String get _defaultFileName {
    final segments = Uri.parse(EnvConfig.llmModelDownloadUrl).pathSegments;
    return segments.isEmpty ? 'gemma3-1b-it-int4.task' : segments.last;
  }

  /// Filename used by flutter_gemma to identify an installed model.
  String get modelFileName => _config?.fileName ?? _defaultFileName;

  String get modelLabel => _config?.label ?? 'On-device model';

  /// The 1B int4 model needs a capable device; gate at the `performance` tier.
  Future<bool> isSupported() async {
    final profile = await _transcriptionService.resolveDeviceProfile();
    return _rank(profile.tier) >= _rank(DevicePerformanceTier.performance);
  }

  Future<bool> isDownloaded() async {
    try {
      // isModelInstalled requires the plugin to be initialized first.
      await _ensureRuntime();
      // Resolve the backend config first so the check uses the *currently
      // configured* model filename, not the bundled fallback — otherwise
      // switching the server-side model would still report the old one as
      // downloaded. Best-effort: fall back to the cached/default name offline.
      await _resolveConfigSafe();
      return await FlutterGemma.isModelInstalled(modelFileName);
    } catch (error) {
      AppLogger.warning('[LocalLLM] isModelInstalled check failed: $error');
      return false;
    }
  }

  /// Resolves the backend model config, swallowing errors so callers that only
  /// need the filename (e.g. the downloaded-state check) still work offline.
  Future<void> _resolveConfigSafe() async {
    try {
      await _resolveConfig();
    } catch (error) {
      AppLogger.warning('[LocalLLM] model config resolve failed: $error');
    }
  }

  Future<LocalLlmModelCatalogEntry> catalogEntry() async {
    // Resolve the backend config up front so label/size/downloaded-state all
    // reflect the currently configured model (best-effort; offline keeps fallbacks).
    await _ensureRuntime();
    await _resolveConfigSafe();
    return LocalLlmModelCatalogEntry(
      label: modelLabel,
      totalBytes: _config?.sizeBytes ?? _gemma1bFallbackBytes,
      isDownloaded: await isDownloaded(),
      isSupported: await isSupported(),
    );
  }

  /// Ensures the runtime is initialized and the model is downloaded and active.
  /// Idempotent: skips the download when the model is already installed.
  Future<void> ensureReady() async {
    await _ensureRuntime();
    final config = await _resolveConfig();
    await FlutterGemma.installModel(
          modelType: config.modelType,
          fileType: config.fileType,
        )
        .fromNetwork(config.url, token: config.token)
        .withProgress(
          (percent) => _progress.add(
            ModelDownloadProgress(bytesDownloaded: percent, totalBytes: 100),
          ),
        )
        .install();
  }

  /// Triggers download from settings without running inference afterward.
  Future<void> download() => ensureReady();

  /// Fetches (and caches) the model download config from the backend.
  Future<_LocalModelConfig> _resolveConfig() async {
    final cached = _config;
    if (cached != null) {
      return cached;
    }

    final response = await _apiClient.request(
      method: 'GET',
      path: '/api/v1/local-summary-model',
      token: _tokenProvider()?.trim(),
    );

    final raw = response.data;
    if (!response.isSuccess || raw is! Map) {
      throw StateError(
        response.message ?? 'Could not fetch the model config from the server.',
      );
    }

    final data = raw.map((key, value) => MapEntry(key.toString(), value));
    final url = (data['url'] ?? '').toString().trim();
    if (url.isEmpty) {
      throw StateError('Server did not return a model download URL.');
    }
    final token = (data['token'] ?? '').toString().trim();
    final fileName = (data['file_name'] ?? '').toString().trim();
    final size = data['size_bytes'];

    final config = _LocalModelConfig(
      url: url,
      // Fall back to a dart-define token if the server has none configured.
      token: token.isNotEmpty
          ? token
          : (EnvConfig.huggingFaceToken.isEmpty
                ? null
                : EnvConfig.huggingFaceToken),
      fileName: fileName.isEmpty ? _defaultFileName : fileName,
      sizeBytes: size is num ? size.toInt() : _gemma1bFallbackBytes,
      modelType: _mapModelType((data['model_type'] ?? '').toString()),
      fileType: _mapFileType((data['file_type'] ?? '').toString()),
      label: (data['label'] ?? '').toString().trim().isEmpty
          ? 'On-device model'
          : data['label'].toString().trim(),
    );
    _config = config;
    return config;
  }

  ModelType _mapModelType(String value) {
    return switch (value) {
      'gemmaIt' => ModelType.gemmaIt,
      'qwen' => ModelType.qwen,
      'qwen3' => ModelType.qwen3,
      'deepSeek' => ModelType.deepSeek,
      'phi' => ModelType.phi,
      'llama' => ModelType.llama,
      'hammer' => ModelType.hammer,
      'general' => ModelType.general,
      _ => ModelType.gemmaIt,
    };
  }

  ModelFileType _mapFileType(String value) {
    return switch (value) {
      'litertlm' => ModelFileType.litertlm,
      'binary' => ModelFileType.binary,
      _ => ModelFileType.task,
    };
  }

  Future<void> _ensureRuntime() async {
    if (_runtimeInitialized) {
      return;
    }
    // The per-download token (from the backend) is applied at install time via
    // fromNetwork(); no token needed here.
    await FlutterGemma.initialize();
    _runtimeInitialized = true;
  }

  int _rank(DevicePerformanceTier tier) {
    return switch (tier) {
      DevicePerformanceTier.entry => 0,
      DevicePerformanceTier.balanced => 1,
      DevicePerformanceTier.performance => 2,
      DevicePerformanceTier.premium => 3,
    };
  }

  Future<void> dispose() async {
    await _progress.close();
  }
}
