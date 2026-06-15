import 'package:flutter_gemma/flutter_gemma.dart';

/// Thin wrapper over flutter_gemma's inference API for single-turn completions.
///
/// Assumes a model has already been installed and set active (see
/// `LocalLlmModelService.ensureReady`).
///
/// Model lifetime: by default each [generate] loads and unloads the model —
/// safe, but loading takes seconds. A caller that runs several inferences in a
/// row (map-reduce summary, a chat exchange) should wrap the run in
/// [acquire]/[release]; the model is then kept open across calls and unloaded
/// when the last lease is released, so memory is never held while idle.
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
  LocalLlmRuntime();

  InferenceModel? _model;
  int _leases = 0;

  /// Keeps the model loaded across subsequent [generate] calls until the
  /// matching [release]. Re-entrant (lease-counted).
  void acquire() => _leases++;

  /// Releases one lease; unloads the model when no leases remain.
  Future<void> release() async {
    if (_leases > 0) {
      _leases--;
    }
    if (_leases == 0) {
      final model = _model;
      _model = null;
      if (model != null) {
        await model.close();
      }
    }
  }

  Future<String> generate({
    required String systemInstruction,
    required String userText,
    // Context window; kept modest for speed (input is capped before this).
    // Ignored when a leased model is already open (its window applies).
    int maxTokens = 2048,
  }) async {
    // GPU backend (needs the OpenCL <uses-native-library> entries in the
    // manifest). We use the int8 (q8) Gemma .task: the int4 q4_block128 variant
    // SIGSEGVs in the OpenCL executor on some devices, and CPU is too slow
    // (minutes); int8 on GPU is the stable, fast path.
    final model =
        _model ??
        await FlutterGemma.getActiveModel(
          maxTokens: maxTokens,
          preferredBackend: PreferredBackend.gpu,
        );
    if (_leases > 0) {
      _model = model;
    }
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
      if (_leases == 0) {
        _model = null;
        await model.close();
      }
    }
  }

  /// Streaming variant of [generate] — yields the response token-by-token via
  /// flutter_gemma's `getResponseAsync`, so the UI can render the answer as it
  /// arrives instead of waiting for the whole completion. Same sampling and
  /// model-lifecycle semantics as [generate].
  Stream<String> generateStream({
    required String systemInstruction,
    required String userText,
    int maxTokens = 2048,
  }) async* {
    final model =
        _model ??
        await FlutterGemma.getActiveModel(
          maxTokens: maxTokens,
          preferredBackend: PreferredBackend.gpu,
        );
    if (_leases > 0) {
      _model = model;
    }
    InferenceModelSession? session;
    try {
      session = await model.createSession(
        temperature: 0.6,
        topK: 40,
        topP: 0.95,
        systemInstruction: systemInstruction,
      );
      await session.addQueryChunk(Message.text(text: userText, isUser: true));
      yield* session.getResponseAsync();
    } finally {
      await session?.close();
      if (_leases == 0) {
        _model = null;
        await model.close();
      }
    }
  }
}
