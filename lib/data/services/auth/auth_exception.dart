class VoiceScribeAuthException implements Exception {
  const VoiceScribeAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
