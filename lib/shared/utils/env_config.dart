class EnvConfig {
  static Future<void> initialize() async {}

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const modelDownloadUrl = String.fromEnvironment(
    'MODEL_DOWNLOAD_URL',
    defaultValue:
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
  );

  static const appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static const isDebugMode = bool.fromEnvironment('DEBUG_MODE');
}
