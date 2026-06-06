import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/data/services/transcription/transcription_estimator.dart';

void main() {
  group('TranscriptionEstimator', () {
    test('uses a per-model seed before any sample is recorded', () {
      final estimator = TranscriptionEstimator();

      // small is seeded slower than base, base slower than tiny.
      expect(
        estimator.factorFor('small'),
        greaterThan(estimator.factorFor('base')),
      );
      expect(
        estimator.factorFor('base'),
        greaterThan(estimator.factorFor('tiny')),
      );
      // Unknown models fall back to a sane default rather than crashing.
      expect(estimator.factorFor('mystery'), greaterThan(0));
    });

    test('estimate scales with pending audio and the model factor', () {
      final estimator = TranscriptionEstimator();
      final baseFactor = estimator.factorFor('base');

      final estimate = estimator.estimateFor(
        modelKey: 'base',
        pendingAudioSeconds: 30,
      );

      expect(estimate.inMilliseconds, (30 * 1000 * baseFactor).round());
    });

    test('returns zero for a non-positive backlog', () {
      final estimator = TranscriptionEstimator();
      expect(
        estimator.estimateFor(modelKey: 'small', pendingAudioSeconds: 0),
        Duration.zero,
      );
      expect(
        estimator.estimateFor(modelKey: 'small', pendingAudioSeconds: -5),
        Duration.zero,
      );
    });

    test('converges toward the measured device speed', () {
      final estimator = TranscriptionEstimator(smoothing: 0.5);

      // Device consistently takes 4s to process 1s of audio (factor 4.0),
      // slower than the small seed. Feed several samples.
      for (var i = 0; i < 12; i++) {
        estimator.record(
          modelKey: 'small',
          audioSeconds: 10,
          processing: const Duration(seconds: 40),
        );
      }

      expect(estimator.factorFor('small'), closeTo(4.0, 0.1));
    });

    test('ignores degenerate samples (zero audio or zero processing)', () {
      final estimator = TranscriptionEstimator();
      final before = estimator.factorFor('base');

      estimator
        ..record(
          modelKey: 'base',
          audioSeconds: 0,
          processing: const Duration(seconds: 5),
        )
        ..record(modelKey: 'base', audioSeconds: 5, processing: Duration.zero);

      expect(estimator.factorFor('base'), before);
    });
  });
}
