import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/data/services/pcm_chunker.dart';

void main() {
  test(
    'closes a chunk at max duration and keeps overlap for the next chunk',
    () {
      final chunker = PcmChunker(
        sampleRate: 10,
        maxDuration: const Duration(seconds: 2),
        overlapDuration: const Duration(milliseconds: 500),
        minDuration: const Duration(milliseconds: 500),
        silenceDuration: const Duration(seconds: 5),
      );

      final chunks = chunker.add(_pcm(samples: 20, value: 12000));

      expect(chunks, hasLength(1));
      expect(chunks.single.reason, PcmChunkCloseReason.maxDuration);
      expect(chunks.single.durationSeconds, 2);

      final flushed = chunker.finish();
      expect(flushed.single.durationSeconds, 0.5);
    },
  );

  test('closes a chunk when enough silence follows minimum duration', () {
    final chunker = PcmChunker(
      sampleRate: 10,
      maxDuration: const Duration(seconds: 10),
      overlapDuration: Duration.zero,
      minDuration: const Duration(seconds: 1),
      silenceDuration: const Duration(seconds: 1),
      silenceThreshold: 0.01,
    );

    expect(chunker.add(_pcm(samples: 10, value: 12000)), isEmpty);
    final chunks = chunker.add(_pcm(samples: 10, value: 0));

    expect(chunks, hasLength(1));
    expect(chunks.single.reason, PcmChunkCloseReason.silence);
  });

  test('levelFor normalizes pcm amplitude', () {
    final chunker = PcmChunker(sampleRate: 10);
    final level = chunker.levelFor(_pcm(samples: 10, value: 16000));

    expect(level, greaterThan(0));
    expect(level, lessThanOrEqualTo(1));
  });

  test('averageLevel excludes overlap region', () {
    final chunker = PcmChunker(
      sampleRate: 10,
      maxDuration: const Duration(seconds: 2),
      minDuration: const Duration(milliseconds: 500),
      silenceDuration: const Duration(seconds: 5),
    );

    chunker.add(_pcm(samples: 10, value: 12000));
    final chunks = chunker.add(_pcm(samples: 10, value: 0));
    expect(chunks, hasLength(1));

    final avgLevel = chunks.single.averageLevel;
    final fullLevel = chunker.levelFor(chunks.single.pcm16Data);
    expect(avgLevel, greaterThan(fullLevel));
  });

  test('averageLevel for flush excludes overlap from previous chunk', () {
    final chunker = PcmChunker(
      sampleRate: 10,
      maxDuration: const Duration(seconds: 2),
      minDuration: const Duration(milliseconds: 500),
      silenceDuration: const Duration(seconds: 5),
    );

    chunker.add(_pcm(samples: 20, value: 12000));
    final flushed = chunker.finish();
    expect(flushed, hasLength(1));
    expect(flushed.single.averageLevel, greaterThanOrEqualTo(0));
  });

  test('silence counter preserves overlap silence after _close', () {
    final chunker = PcmChunker(
      sampleRate: 10,
      maxDuration: const Duration(seconds: 10),
      overlapDuration: Duration.zero,
      minDuration: const Duration(seconds: 1),
      silenceDuration: const Duration(seconds: 1),
      silenceThreshold: 0.01,
    );

    expect(chunker.add(_pcm(samples: 10, value: 12000)), isEmpty);
    expect(chunker.add(_pcm(samples: 10, value: 0)), hasLength(1));

    final flushed = chunker.finish();
    expect(flushed, isEmpty);
  });

  test(
    'sample-level silence tracking does not reset on single loud sample in batch',
    () {
      final chunker = PcmChunker(
        maxDuration: const Duration(seconds: 30),
        overlapDuration: Duration.zero,
      );

      final loudBatch = _pcm(samples: 3200, value: 12000);
      expect(chunker.add(loudBatch), isEmpty);

      final silentBatch = _pcm(samples: 32000, value: 0);
      expect(chunker.add(silentBatch), isNotEmpty);
    },
  );

  test('_overlapSamples is tracked and used in finish averageLevel', () {
    final chunker = PcmChunker(
      sampleRate: 10,
      maxDuration: const Duration(seconds: 2),
      minDuration: const Duration(milliseconds: 500),
      silenceDuration: const Duration(seconds: 5),
    );

    chunker.add(_pcm(samples: 20, value: 12000));

    final loudFlush = _pcm(samples: 10, value: 16000);
    chunker.add(loudFlush);
    final flushed = chunker.finish();

    expect(flushed, hasLength(1));
    expect(flushed.single.averageLevel, greaterThan(0));
  });

  test(
    'trims trailing silence on a silence-closed chunk (keeps 250ms guard)',
    () {
      final chunker = PcmChunker(
        sampleRate: 100,
        maxDuration: const Duration(seconds: 10),
        overlapDuration: Duration.zero,
        minDuration: const Duration(seconds: 1),
        silenceDuration: const Duration(seconds: 1),
      );

      // 100 speech samples (1s) then 150 silence samples (1.5s) → closes on
      // silence. Raw = 250 samples (2.5s); trim removes 150-25(guard)=125
      // samples → 125 samples (1.25s) kept.
      expect(chunker.add(_pcm(samples: 100, value: 12000)), isEmpty);
      final chunks = chunker.add(_pcm(samples: 150, value: 0));

      expect(chunks, hasLength(1));
      expect(chunks.single.reason, PcmChunkCloseReason.silence);
      expect(chunks.single.durationSeconds, closeTo(1.25, 0.001));
      expect(chunks.single.pcm16Data.length, 250); // 125 samples * 2 bytes
    },
  );

  test('does not trim a max-duration chunk even with trailing silence', () {
    final chunker = PcmChunker(
      sampleRate: 100,
      maxDuration: const Duration(seconds: 2),
      overlapDuration: Duration.zero,
      minDuration: const Duration(milliseconds: 500),
      silenceDuration: const Duration(seconds: 5),
    );

    // 100 speech + 100 silence = 200 samples → closes at maxDuration (2s).
    // Silence-trim must NOT apply to a mid-speech max-duration close.
    chunker.add(_pcm(samples: 100, value: 12000));
    final chunks = chunker.add(_pcm(samples: 100, value: 0));

    expect(chunks, hasLength(1));
    expect(chunks.single.reason, PcmChunkCloseReason.maxDuration);
    expect(chunks.single.durationSeconds, 2);
  });
}

Uint8List _pcm({required int samples, required int value}) {
  final data = ByteData(samples * 2);
  for (var i = 0; i < samples; i++) {
    final sample = (value * math.sin(i + 1)).round();
    data.setInt16(i * 2, sample, Endian.little);
  }
  return data.buffer.asUint8List();
}
