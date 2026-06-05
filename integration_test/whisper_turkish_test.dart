// On-device transcription smoke test.
//
// The Android emulator on this machine does not forward host microphone audio
// into the guest (the guest HAL only ever sees silence, even with
// `-allow-host-audio` and an active PipeWire capture stream). To validate the
// real on-device Whisper pipeline despite that, this test feeds a known Turkish
// 16 kHz mono WAV directly to `WhisperTranscriptionService.transcribeChunk`,
// bypassing the microphone, and prints the transcription so it can be inspected.
//
// Prereq: push the sample next to the app's external files dir first:
//   adb push turkish16k.wav /sdcard/Android/data/com.voicescribe.app/files/
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'on-device base model transcribes a Turkish WAV (mic bypassed)',
    (tester) async {
      final service = WhisperTranscriptionService();

      // Load the bundled sample and stage it as a file (transcribeChunk needs a
      // path). Bundling as an asset survives the test-runner's reinstall, which
      // wipes the app's external storage.
      final bytes = await rootBundle.load('test_assets/turkish16k.wav');
      final tmpDir = await getTemporaryDirectory();
      final wavPath = '${tmpDir.path}/turkish16k.wav';
      await File(wavPath).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      // ignore: avoid_print
      print('WAV_PATH: $wavPath bytes=${bytes.lengthInBytes}');
      expect(File(wavPath).existsSync(), isTrue, reason: 'sample WAV missing');

      final boot = await service.ensureModel();
      // ignore: avoid_print
      print('MODEL_READY path=${boot.path} downloaded=${boot.downloaded}');

      service.setTranscriptionLanguage('tr');

      final result = await service.transcribeChunk(wavPath, audioLevel: 0.1);

      // ignore: avoid_print
      print('TR_RESULT>>>${result.text.trim()}<<<TR_RESULT');
      for (final s in result.segments) {
        // ignore: avoid_print
        print(
          'SEG[${s.startSeconds.toStringAsFixed(1)}-'
          '${s.endSeconds.toStringAsFixed(1)}]: ${s.text}',
        );
      }

      expect(
        result.text.trim().isNotEmpty,
        isTrue,
        reason: 'transcription came back empty',
      );

      await service.dispose();
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
