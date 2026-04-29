import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/utils/env_config.dart';

class SpeakerEmbeddingSample {
  const SpeakerEmbeddingSample({
    required this.speakerId,
    required this.embedding,
  });

  final String speakerId;
  final List<double> embedding;
}

class SpeakerAnalysisService {
  SpeakerAnalysisService({
    Interpreter? interpreter,
    double? similarityThreshold,
  }) : _interpreter = interpreter,
       _similarityThreshold =
           similarityThreshold ?? EnvConfig.speakerSimilarityThreshold;

  Interpreter? _interpreter;
  String? _materializedModelPath;
  double _similarityThreshold;
  bool _interpreterLoadAttempted = false;

  double get similarityThreshold => _similarityThreshold;

  void setSimilarityThreshold(double value) {
    if (value < 0.55) {
      _similarityThreshold = 0.55;
      return;
    }
    if (value > 0.95) {
      _similarityThreshold = 0.95;
      return;
    }
    _similarityThreshold = value;
  }

  bool shouldSkipChunk(TranscriptChunk chunk) {
    final duration = chunk.endTime - chunk.startTime;
    return duration < 2 || chunk.text.trim().isEmpty;
  }

  Future<List<double>> embeddingForChunk(TranscriptChunk chunk) async {
    final audioPath = chunk.audioPath;
    if (audioPath == null || audioPath.trim().isEmpty) {
      throw StateError('Speaker analysis requires chunk audio path.');
    }
    final signal = await _readNormalizedSignal(audioPath);
    if (signal.isEmpty) {
      throw StateError('Chunk audio signal is empty.');
    }

    final interpreter = await _resolveInterpreter();
    if (interpreter == null) {
      return _signalEmbedding(signal);
    }
    try {
      return _runInterpreter(interpreter, signal);
    } catch (_) {
      return _signalEmbedding(signal);
    }
  }

  ({String? speakerId, double confidence}) matchSpeaker({
    required List<double> chunkEmbedding,
    required List<SpeakerProfile> speakers,
    double? threshold,
  }) {
    final matchThreshold = threshold ?? _similarityThreshold;
    String? bestSpeakerId;
    var bestScore = 0.0;

    for (final speaker in speakers) {
      if (speaker.embedding.isEmpty) continue;
      final score = cosineSimilarity(chunkEmbedding, speaker.embedding);
      if (score > bestScore) {
        bestScore = score;
        bestSpeakerId = speaker.id;
      }
    }

    if (bestScore >= matchThreshold) {
      return (speakerId: bestSpeakerId, confidence: bestScore);
    }

    return (speakerId: null, confidence: bestScore);
  }

  double? calibrateSimilarityThreshold({
    required List<SpeakerEmbeddingSample> samples,
  }) {
    if (samples.length < 6) {
      return null;
    }
    final uniqueSpeakers = samples.map((item) => item.speakerId).toSet();
    if (uniqueSpeakers.length < 2) {
      return null;
    }

    final positives = <double>[];
    final negatives = <double>[];

    for (var i = 0; i < samples.length; i++) {
      for (var j = i + 1; j < samples.length; j++) {
        final score = cosineSimilarity(
          samples[i].embedding,
          samples[j].embedding,
        );
        if (samples[i].speakerId == samples[j].speakerId) {
          positives.add(score);
        } else {
          negatives.add(score);
        }
      }
    }

    if (positives.isEmpty || negatives.isEmpty) {
      return null;
    }

    final candidates = {...positives, ...negatives}.toList()..sort();
    var bestThreshold = _similarityThreshold;
    var bestScore = double.negativeInfinity;

    for (final threshold in candidates) {
      final truePositiveRate =
          positives.where((score) => score >= threshold).length /
          positives.length;
      final trueNegativeRate =
          negatives.where((score) => score < threshold).length /
          negatives.length;
      final score = truePositiveRate + trueNegativeRate;
      if (score > bestScore) {
        bestScore = score;
        bestThreshold = threshold;
      }
    }

    setSimilarityThreshold(bestThreshold);
    return _similarityThreshold;
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    final minLen = math.min(a.length, b.length);
    if (minLen == 0) return 0;

    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < minLen; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  Future<Interpreter?> _resolveInterpreter() async {
    if (_interpreter != null || _interpreterLoadAttempted) {
      return _interpreter;
    }
    _interpreterLoadAttempted = true;

    final modelPath = EnvConfig.speakerModelPath.trim();
    if (modelPath.isEmpty) {
      return null;
    }

    final resolvedModelPath = await _resolveModelPath(modelPath);
    if (resolvedModelPath == null) {
      return null;
    }

    final modelFile = File(resolvedModelPath);
    if (!modelFile.existsSync()) {
      return null;
    }

    return _interpreter = Interpreter.fromFile(modelFile);
  }

  Future<String?> _resolveModelPath(String modelPath) async {
    if (!modelPath.startsWith('asset:')) {
      return modelPath;
    }
    if (_materializedModelPath != null && _materializedModelPath!.isNotEmpty) {
      return _materializedModelPath;
    }

    final assetPath = modelPath.substring('asset:'.length);
    final data = await rootBundle.load(assetPath);
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/speaker_model.tflite');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return _materializedModelPath = file.path;
  }

  Future<List<double>> _readNormalizedSignal(String audioPath) async {
    final file = File(audioPath);
    if (!file.existsSync()) {
      return const <double>[];
    }
    final bytes = await file.readAsBytes();
    if (bytes.length < 44) {
      return const <double>[];
    }

    final pcmData = bytes.sublist(44);
    if (pcmData.isEmpty) {
      return const <double>[];
    }
    final sampleCount = pcmData.length ~/ 2;
    final bd = ByteData.sublistView(pcmData);
    final signal = List<double>.filled(sampleCount, 0);

    for (var i = 0; i < sampleCount; i++) {
      final sample = bd.getInt16(i * 2, Endian.little);
      signal[i] = sample / 32768.0;
    }
    return signal;
  }

  List<double> _runInterpreter(Interpreter interpreter, List<double> signal) {
    final inputSize = EnvConfig.speakerModelInputLength;
    final normalizedInput = List<double>.filled(inputSize, 0);
    for (var i = 0; i < inputSize; i++) {
      final srcIndex = (i * signal.length / inputSize).floor();
      normalizedInput[i] = signal[srcIndex.clamp(0, signal.length - 1)];
    }

    final outputShape = interpreter.getOutputTensor(0).shape;
    final outputLength = outputShape.fold<int>(1, (a, b) => a * b);
    final output = List<double>.filled(outputLength, 0);

    final input = [normalizedInput];
    final outputBuffer = [output];
    interpreter.run(input, outputBuffer);

    return _l2Normalize(outputBuffer.first.cast<double>());
  }

  List<double> _signalEmbedding(List<double> signal) {
    const bins = 32;
    if (signal.isEmpty) {
      return List<double>.filled(bins, 0);
    }

    final chunkSize = math.max(1, signal.length ~/ bins);
    final vector = List<double>.filled(bins, 0);
    for (var i = 0; i < bins; i++) {
      final start = i * chunkSize;
      if (start >= signal.length) {
        break;
      }
      final end = math.min(signal.length, start + chunkSize);
      var sumAbs = 0.0;
      var sumSquare = 0.0;
      for (var j = start; j < end; j++) {
        final value = signal[j];
        sumAbs += value.abs();
        sumSquare += value * value;
      }
      final len = (end - start).toDouble();
      final meanAbs = len == 0 ? 0.0 : sumAbs / len;
      final rms = len == 0 ? 0.0 : math.sqrt(sumSquare / len);
      vector[i] = (meanAbs + rms) / 2;
    }

    return _l2Normalize(vector);
  }

  List<double> _l2Normalize(List<double> vector) {
    var norm = 0.0;
    for (final value in vector) {
      norm += value * value;
    }
    if (norm == 0) {
      return vector;
    }
    final denom = math.sqrt(norm);
    return vector.map((value) => value / denom).toList(growable: false);
  }
}
