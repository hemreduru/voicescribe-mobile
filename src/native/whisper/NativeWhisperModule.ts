/**
 * Native whisper.cpp module interface.
 * Bridges to C++ whisper inference via JNI (Android) and ObjC++ (iOS).
 */

export interface WhisperTranscriptSegment {
  /** Transcribed text for this segment */
  text: string;
  /** Start time in milliseconds */
  startMs: number;
  /** End time in milliseconds */
  endMs: number;
  /** Confidence score (0.0 - 1.0) */
  confidence: number;
}

export interface WhisperModelInfo {
  /** Model identifier (e.g., 'tiny', 'base') */
  modelId: string;
  /** Model file path on device */
  path: string;
  /** Whether the model is currently loaded */
  isLoaded: boolean;
  /** Model file size in bytes */
  sizeBytes: number;
}

export interface NativeWhisperModule {
  /** Load a GGUF model into memory */
  loadModel(modelPath: string, threadCount?: number): Promise<void>;

  /** Unload the current model to free memory */
  unloadModel(): Promise<void>;

  /** Check if a model is currently loaded */
  isModelLoaded(): Promise<boolean>;

  /**
   * Transcribe a PCM audio chunk.
   * @param audioData - Base64 encoded PCM 16-bit mono 16kHz audio
   * @returns Array of transcript segments
   */
  transcribe(audioData: string): Promise<WhisperTranscriptSegment[]>;

  /** Get info about available models on device */
  getAvailableModels(): Promise<WhisperModelInfo[]>;

  /** Download a model to device storage */
  downloadModel(modelId: string, url: string): Promise<string>;
}
