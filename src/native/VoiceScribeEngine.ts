import {
  VoiceScribeAudio,
  type AudioChunk,
  type WhisperBootstrapResult,
  type WhisperTranscriptionErrorEvent,
  type WhisperTranscriptEvent,
} from './audio/NativeAudioModule';

type Subscription = { remove: () => void };

/**
 * Thin runtime wrapper that unifies native audio capture + whisper inference
 * calls behind a single API for feature-layer usage.
 */
export class VoiceScribeEngine {
  startRecording(): void {
    VoiceScribeAudio.startRecording();
  }

  stopRecording(): void {
    VoiceScribeAudio.stopRecording();
  }

  async loadModel(modelPath: string): Promise<boolean> {
    return VoiceScribeAudio.loadWhisperModel(modelPath);
  }

  async downloadModel(modelUrl: string, fileName: string): Promise<string> {
    return VoiceScribeAudio.downloadWhisperModel(modelUrl, fileName);
  }

  async ensureModel(modelUrl: string, fileName: string): Promise<WhisperBootstrapResult> {
    return VoiceScribeAudio.ensureWhisperModel(modelUrl, fileName);
  }

  async unloadModel(): Promise<void> {
    await VoiceScribeAudio.unloadWhisperModel();
  }

  async isModelLoaded(): Promise<boolean> {
    return VoiceScribeAudio.isWhisperModelLoaded();
  }

  async transcribeChunk(chunkPath: string): Promise<string> {
    return VoiceScribeAudio.transcribeChunk(chunkPath);
  }

  onChunkReady(callback: (chunk: AudioChunk) => void): Subscription {
    return VoiceScribeAudio.onChunkReady(callback);
  }

  onTranscriptReady(callback: (event: WhisperTranscriptEvent) => void): Subscription {
    return VoiceScribeAudio.onTranscriptReady(callback);
  }

  onTranscriptionError(callback: (event: WhisperTranscriptionErrorEvent) => void): Subscription {
    return VoiceScribeAudio.onTranscriptionError(callback);
  }
}
