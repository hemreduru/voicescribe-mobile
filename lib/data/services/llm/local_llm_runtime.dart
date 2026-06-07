import 'package:flutter_gemma/flutter_gemma.dart';

/// Thin wrapper over flutter_gemma's inference API for a single-turn completion.
///
/// Assumes a model has already been installed and set active (see
/// `LocalLlmModelService.ensureReady`).
class LocalLlmRuntime {
  const LocalLlmRuntime();

  Future<String> generate({
    required String systemInstruction,
    required String userText,
    // Context window; kept modest for speed (input is capped before this).
    int maxTokens = 2048,
  }) async {
    // GPU backend (requires the OpenCL <uses-native-library> entries in
    // AndroidManifest). CPU inference of these models is impractically slow
    // (minutes); GPU brings it to seconds, matching Google AI Edge Gallery.
    final model = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: PreferredBackend.gpu,
    );
    InferenceModelSession? session;
    try {
      // Greedy decoding (topK=1) makes small models loop/repeat; sample with a
      // modest topK/topP + temperature to keep output coherent and terminating.
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
