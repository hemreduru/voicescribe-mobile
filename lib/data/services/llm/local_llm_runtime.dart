import 'package:flutter_gemma/flutter_gemma.dart';

/// Thin wrapper over flutter_gemma's inference API for a single-turn completion.
///
/// Assumes a model has already been installed and set active (see
/// `LocalLlmModelService.ensureReady`).
///
/// NOTE: flutter_gemma (v0.13.x) exposes no constrained-decoding / JSON-schema /
/// grammar / response-format option on `createSession` — only sampling params
/// and a `systemInstruction`. So valid-JSON output cannot be guaranteed by the
/// runtime; the guarantee lives at the boundary instead (the tightened few-shot
/// prompt in `MeetingMinutesPrompt.system` plus the tolerant
/// `MeetingSummary.tryParse` repair/normalize layer). If a future version adds
/// schema-constrained output, bind the MeetingSummary schema here — that would
/// be the strongest lever.
class LocalLlmRuntime {
  const LocalLlmRuntime();

  Future<String> generate({
    required String systemInstruction,
    required String userText,
    // Context window; kept modest for speed (input is capped before this).
    int maxTokens = 2048,
  }) async {
    // GPU backend (needs the OpenCL <uses-native-library> entries in the
    // manifest). We use the int8 (q8) Gemma .task: the int4 q4_block128 variant
    // SIGSEGVs in the OpenCL executor on some devices, and CPU is too slow
    // (minutes); int8 on GPU is the stable, fast path.
    final model = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: PreferredBackend.gpu,
    );
    InferenceModelSession? session;
    try {
      // Greedy decoding (topK=1) makes small models loop/repeat; sample with a
      // modest topK/topP + temperature to keep output coherent and terminating.
      // 0.6 is the current stable point; a lower value (≈0.3–0.4) may improve
      // JSON adherence but risks repetition loops on these tiny models, so any
      // change should be validated with an on-device corpus sweep
      // (integration_test/local_summary_small_test.dart) before lowering.
      session = await model.createSession(
        temperature: 0.6,
        topK: 40,
        topP: 0.95,
        systemInstruction: systemInstruction,
      );
      await session.addQueryChunk(Message.text(text: userText, isUser: true));
      return await session.getResponse();
    } finally {
      await session?.close();
      await model.close();
    }
  }
}
