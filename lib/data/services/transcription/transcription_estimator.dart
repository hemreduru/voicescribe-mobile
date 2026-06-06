/// Estimates how long on-device transcription of a backlog will take *on this
/// specific device*.
///
/// The key quantity is the **realtime factor**: processing seconds per second
/// of audio. A factor of `3.2` means a 10-second clip takes ~32 seconds to
/// transcribe. It varies a lot by device and by model (the `small` Whisper
/// model is several times slower than `base`), so a fixed guess would be
/// misleading — instead we seed a sensible per-model default and then refine it
/// from real measurements as chunks complete, converging on a number that is
/// accurate for the hardware actually in the user's hand.
///
/// This class is deliberately pure (no IO, no Flutter) so it can be unit-tested
/// and so the transcription service can own one instance and feed it samples.
class TranscriptionEstimator {
  TranscriptionEstimator({double smoothing = 0.4})
    : assert(smoothing > 0 && smoothing <= 1, 'smoothing must be in (0, 1]'),
      _smoothing = smoothing;

  /// EWMA weight for a fresh sample. Higher = adapts faster but noisier.
  final double _smoothing;

  /// Current realtime factor per model key, refined as samples arrive.
  final Map<String, double> _factorByModel = {};

  /// Per-model starting guesses, measured on real devices (a mid-tier tablet:
  /// base ≈ realtime, small ≈ 3x realtime; tiny is roughly half of base). Used
  /// only until the first real sample for that model lands.
  static const Map<String, double> _seedFactor = {
    'tiny': 0.6,
    'base': 1.1,
    'small': 3.2,
  };

  static const double _fallbackSeed = 1.1;

  /// Record one completed transcription: [audioSeconds] of audio took
  /// [processing] wall-clock time. Silent/zero-length clips are ignored so they
  /// don't skew the factor.
  void record({
    required String modelKey,
    required double audioSeconds,
    required Duration processing,
  }) {
    if (audioSeconds <= 0 || processing <= Duration.zero) {
      return;
    }
    final sample = processing.inMilliseconds / (audioSeconds * 1000);
    if (!sample.isFinite || sample <= 0) {
      return;
    }
    final previous = _factorByModel[modelKey] ?? _seedFor(modelKey);
    _factorByModel[modelKey] = previous + _smoothing * (sample - previous);
  }

  /// Best current estimate of the realtime factor for [modelKey].
  double factorFor(String modelKey) =>
      _factorByModel[modelKey] ?? _seedFor(modelKey);

  /// Estimated wall-clock time to transcribe [pendingAudioSeconds] of audio
  /// with [modelKey]. Returns [Duration.zero] when there's nothing pending.
  Duration estimateFor({
    required String modelKey,
    required double pendingAudioSeconds,
  }) {
    if (pendingAudioSeconds <= 0) {
      return Duration.zero;
    }
    final millis = pendingAudioSeconds * 1000 * factorFor(modelKey);
    return Duration(milliseconds: millis.round());
  }

  double _seedFor(String modelKey) => _seedFactor[modelKey] ?? _fallbackSeed;
}
