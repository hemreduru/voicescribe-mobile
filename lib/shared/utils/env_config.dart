import 'dart:io';

class EnvConfig {
  static bool _initialized = false;
  static final Map<String, String> _values = <String, String>{};

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _values['API_BASE_URL'] = 'http://vsbackend.test';
    _values['MODEL_DOWNLOAD_URL'] =
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin';
    _values['APP_ENV'] = 'production';
    _values['DEBUG_MODE'] = 'false';
    _values['SUPABASE_URL'] = 'https://njkhmtjghtfbajslbhbp.supabase.co';
    _values['SUPABASE_ANON_KEY'] =
        'sb_publishable_Ib4JZcs0zf5mHel8j3kK3A_O0XFQiAi';
    _values['SPEAKER_MODEL_PATH'] =
        'asset:assets/models/conformer_tisid_small.tflite';
    _values['SPEAKER_MODEL_INPUT_LENGTH'] = '16000';
    _values['SPEAKER_SIMILARITY_THRESHOLD'] = '0.78';

    _loadDotEnvFile();
    _applyDartDefines();

    _initialized = true;
  }

  static String get apiBaseUrl =>
      _values['API_BASE_URL'] ?? 'http://vsbackend.test';

  static String get modelDownloadUrl =>
      _values['MODEL_DOWNLOAD_URL'] ??
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin';

  static String get appEnv => _values['APP_ENV'] ?? 'production';

  static bool get isDebugMode => _toBool(_values['DEBUG_MODE']);

  static String get supabaseUrl => _values['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => _values['SUPABASE_ANON_KEY'] ?? '';

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
      'SUPABASE_URL',
      const String.fromEnvironment('SUPABASE_URL'),
    );
    _applyDefinedValue(
      'SUPABASE_ANON_KEY',
      const String.fromEnvironment('SUPABASE_ANON_KEY'),
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
