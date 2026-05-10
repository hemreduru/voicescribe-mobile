import 'dart:io';

class EnvConfig {
  static bool _initialized = false;
  static final Map<String, String> _values = <String, String>{};
  static const String _defaultApiBaseUrl = 'http://vsbackend.test';
  static const String _androidHostLoopback = '10.0.2.2';
  static const String _localBackendLanHost = '192.168.8.20';
  static const Set<String> _androidEmulatorLoopbackAliases = <String>{
    'localhost',
    '127.0.0.1',
  };
  static const Set<String> _androidLocalDnsAliases = <String>{'vsbackend.test'};

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _values['API_BASE_URL'] = _defaultApiBaseUrl;
    _values['MODEL_DOWNLOAD_URL'] =
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin';
    _values['APP_ENV'] = 'production';
    _values['DEBUG_MODE'] = 'false';
    _values['SPEAKER_MODEL_PATH'] =
        'asset:assets/models/conformer_tisid_small.tflite';
    _values['SPEAKER_MODEL_INPUT_LENGTH'] = '16000';
    _values['SPEAKER_SIMILARITY_THRESHOLD'] = '0.78';

    _loadDotEnvFile();
    _applyDartDefines();

    _initialized = true;
  }

  static String get apiBaseUrl {
    final raw = (_values['API_BASE_URL'] ?? _defaultApiBaseUrl).trim();
    if (raw.isEmpty) {
      return _defaultApiBaseUrl;
    }
    return _normalizeApiBaseUrl(raw);
  }

  static String get modelDownloadUrl =>
      _values['MODEL_DOWNLOAD_URL'] ??
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin';

  static String get appEnv => _values['APP_ENV'] ?? 'production';

  static bool get isDebugMode => _toBool(_values['DEBUG_MODE']);

  /// Returns true when running in a development/testing/local environment.
  /// Used to enable debug auth bypass (password-free login).
  static bool get isTestEnvironment {
    final env = appEnv.toLowerCase();
    return env == 'development' || env == 'testing' || env == 'local';
  }

  static String get speakerModelPath => _values['SPEAKER_MODEL_PATH'] ?? '';

  static int get speakerModelInputLength =>
      _toInt(_values['SPEAKER_MODEL_INPUT_LENGTH'], defaultValue: 16000);

  static double get speakerSimilarityThreshold =>
      _toDouble(_values['SPEAKER_SIMILARITY_THRESHOLD'], defaultValue: 0.78);

  static void _loadDotEnvFile() {
    final envFile = File('.env');
    if (!envFile.existsSync()) {
      return;
    }

    final lines = envFile.readAsLinesSync();
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      final separatorIndex = line.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = line.substring(0, separatorIndex).trim();
      var value = line.substring(separatorIndex + 1).trim();
      if (value.startsWith('"') && value.endsWith('"') && value.length >= 2) {
        value = value.substring(1, value.length - 1);
      }
      _values[key] = value;
    }
  }

  static void _applyDartDefines() {
    _applyDefinedValue(
      'API_BASE_URL',
      const String.fromEnvironment('API_BASE_URL'),
    );
    _applyDefinedValue(
      'MODEL_DOWNLOAD_URL',
      const String.fromEnvironment('MODEL_DOWNLOAD_URL'),
    );
    _applyDefinedValue('APP_ENV', const String.fromEnvironment('APP_ENV'));
    _applyDefinedValue(
      'DEBUG_MODE',
      const String.fromEnvironment('DEBUG_MODE'),
    );
    _applyDefinedValue(
      'SPEAKER_MODEL_PATH',
      const String.fromEnvironment('SPEAKER_MODEL_PATH'),
    );
    _applyDefinedValue(
      'SPEAKER_MODEL_INPUT_LENGTH',
      const String.fromEnvironment('SPEAKER_MODEL_INPUT_LENGTH'),
    );
    _applyDefinedValue(
      'SPEAKER_SIMILARITY_THRESHOLD',
      const String.fromEnvironment('SPEAKER_SIMILARITY_THRESHOLD'),
    );
  }

  static void _applyDefinedValue(String key, String value) {
    if (value.isNotEmpty) {
      _values[key] = value;
    }
  }

  static String _normalizeApiBaseUrl(String raw) {
    if (!Platform.isAndroid) {
      return raw;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.trim().isEmpty) {
      return raw;
    }
    final host = uri.host.toLowerCase();
    if (_androidEmulatorLoopbackAliases.contains(host)) {
      return uri.replace(host: _androidHostLoopback).toString();
    }
    if (_androidLocalDnsAliases.contains(host)) {
      return uri.replace(host: _localBackendLanHost).toString();
    }
    return raw;
  }

  static bool _toBool(String? value) {
    if (value == null) {
      return false;
    }
    final normalized = value.toLowerCase().trim();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on';
  }

  static int _toInt(String? value, {required int defaultValue}) {
    if (value == null) {
      return defaultValue;
    }
    return int.tryParse(value.trim()) ?? defaultValue;
  }

  static double _toDouble(String? value, {required double defaultValue}) {
    if (value == null) {
      return defaultValue;
    }
    return double.tryParse(value.trim()) ?? defaultValue;
  }
}
