import 'dart:math' as math;
import 'dart:typed_data';

class PcmChunk {
  const PcmChunk({
    required this.index,
    required this.pcm16Data,
    required this.durationSeconds,
    required this.reason,
    required this.averageLevel,
  });

  final int index;
  final Uint8List pcm16Data;
  final double durationSeconds;
  final PcmChunkCloseReason reason;
  final double averageLevel;
}

enum PcmChunkCloseReason { maxDuration, silence, flush }

class PcmChunker {
  PcmChunker({
    this.sampleRate = 16000,
    this.maxDuration = const Duration(seconds: 15),
    this.overlapDuration = const Duration(seconds: 1),
    this.minDuration = const Duration(seconds: 2),
    this.silenceDuration = const Duration(milliseconds: 1500),
    this.silenceThreshold = 0.035,
  });

  final int sampleRate;
  final Duration maxDuration;
  final Duration overlapDuration;
  final Duration minDuration;
  final Duration silenceDuration;
  final double silenceThreshold;

  final List<int> _buffer = [];
  int _silentSamples = 0;
  int _chunkIndex = 0;
  int _overlapSamples = 0;

  static const int bytesPerSample = 2;

  List<PcmChunk> add(Uint8List pcm16Data) {
    if (pcm16Data.isEmpty) {
      return const [];
    }

    _buffer.addAll(pcm16Data);
    _trackSilence(pcm16Data);

    final shouldCloseByMax = _sampleCount >= _durationToSamples(maxDuration);
    final shouldCloseBySilence =
        _sampleCount >= _durationToSamples(minDuration) &&
        _silentSamples >= _durationToSamples(silenceDuration);

    if (!shouldCloseByMax && !shouldCloseBySilence) {
      return const [];
    }

    return [
      _close(
        shouldCloseByMax
            ? PcmChunkCloseReason.maxDuration
            : PcmChunkCloseReason.silence,
      ),
    ];
  }

  List<PcmChunk> finish() {
    if (_buffer.isEmpty) {
      return const [];
    }
    final pcm = Uint8List.fromList(_buffer);
    final nonOverlapBytes = (_sampleCount - _overlapSamples) * bytesPerSample;
    final avgLevel = nonOverlapBytes > 0
        ? _averageLevelFor(
            Uint8List.fromList(
              pcm.sublist(nonOverlapBytes.clamp(0, pcm.length)),
            ),
          )
        : _averageLevelFor(pcm);
    final chunk = PcmChunk(
      index: ++_chunkIndex,
      pcm16Data: pcm,
      durationSeconds: _sampleCount / sampleRate,
      reason: PcmChunkCloseReason.flush,
      averageLevel: avgLevel,
    );
    reset(keepIndex: true);
    return [chunk];
  }

  void reset({bool keepIndex = false}) {
    _buffer.clear();
    _silentSamples = 0;
    _overlapSamples = 0;
    if (!keepIndex) {
      _chunkIndex = 0;
    }
  }

  double levelFor(Uint8List pcm16Data) {
    if (pcm16Data.length < bytesPerSample) {
      return 0;
    }
    var sumSquares = 0.0;
    var samples = 0;
    for (var i = 0; i + 1 < pcm16Data.length; i += bytesPerSample) {
      final sample = _readInt16(pcm16Data, i) / 32768.0;
      sumSquares += sample * sample;
      samples++;
    }
    if (samples == 0) {
      return 0;
    }
    final rms = math.sqrt(sumSquares / samples);
    return (rms / 0.25).clamp(0.0, 1.0);
  }

  int get _sampleCount => _buffer.length ~/ bytesPerSample;

  PcmChunk _close(PcmChunkCloseReason reason) {
    final pcm = Uint8List.fromList(_buffer);
    final durationSeconds = _sampleCount / sampleRate;

    final overlapBytes = _durationToSamples(overlapDuration) * bytesPerSample;
    final nonOverlapBytes = (pcm.length - overlapBytes).clamp(0, pcm.length);
    final avgLevel = nonOverlapBytes > 0
        ? _averageLevelFor(Uint8List.fromList(pcm.sublist(0, nonOverlapBytes)))
        : _averageLevelFor(pcm);

    final chunk = PcmChunk(
      index: ++_chunkIndex,
      pcm16Data: pcm,
      durationSeconds: durationSeconds,
      reason: reason,
      averageLevel: avgLevel,
    );

    if (overlapBytes > 0 && _buffer.length > overlapBytes) {
      final tail = _buffer.sublist(_buffer.length - overlapBytes);
      _buffer
        ..clear()
        ..addAll(tail);
      _overlapSamples = _durationToSamples(overlapDuration);
      _silentSamples = _countSilentSamples(tail);
    } else {
      _buffer.clear();
      _overlapSamples = 0;
      _silentSamples = 0;
    }
    return chunk;
  }

  void _trackSilence(Uint8List pcm16Data) {
    final batchLevel = levelFor(pcm16Data);
    if (batchLevel <= silenceThreshold) {
      _silentSamples += pcm16Data.length ~/ bytesPerSample;
    } else {
      _silentSamples = 0;
    }
  }

  int _countSilentSamples(List<int> data) {
    var count = 0;
    for (var i = 0; i + 1 < data.length; i += bytesPerSample) {
      final sample = _readInt16(Uint8List.fromList(data), i) / 32768.0;
      if (sample * sample <= silenceThreshold * silenceThreshold * 0.0625) {
        count++;
      }
    }
    return count;
  }

  double _averageLevelFor(Uint8List pcm16Data) {
    if (pcm16Data.length < bytesPerSample) {
      return 0;
    }
    var sumSquares = 0.0;
    var samples = 0;
    for (var i = 0; i + 1 < pcm16Data.length; i += bytesPerSample) {
      final sample = _readInt16(pcm16Data, i) / 32768.0;
      sumSquares += sample * sample;
      samples++;
    }
    if (samples == 0) {
      return 0;
    }
    final rms = math.sqrt(sumSquares / samples);
    return (rms / 0.25).clamp(0.0, 1.0);
  }

  int _durationToSamples(Duration duration) {
    return (sampleRate *
            duration.inMicroseconds /
            Duration.microsecondsPerSecond)
        .round();
  }

  int _readInt16(Uint8List bytes, int offset) {
    final value = bytes[offset] | (bytes[offset + 1] << 8);
    return value >= 0x8000 ? value - 0x10000 : value;
  }
}
