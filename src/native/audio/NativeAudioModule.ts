/**
 * Native audio recording module interface.
 * Bridges to Android AudioRecord and iOS AVAudioEngine.
 */

export interface AudioChunk {
  /** Raw PCM data encoded as base64 */
  data: string;
  /** Chunk index in the current recording session */
  index: number;
  /** Timestamp when the chunk started (ms since epoch) */
  startTimestamp: number;
  /** Duration of this chunk in milliseconds */
  durationMs: number;
  /** Sample rate in Hz (expected: 16000) */
  sampleRate: number;
}

export interface AudioModuleConfig {
  /** Sample rate in Hz (default: 16000) */
  sampleRate?: number;
  /** Chunk duration in seconds (default: 10) */
  chunkDurationSeconds?: number;
  /** Audio channels (default: 1 = mono) */
  channels?: number;
  /** Bits per sample (default: 16) */
  bitsPerSample?: number;
}

export interface NativeAudioModule {
  /** Start continuous audio recording */
  startRecording(config?: AudioModuleConfig): Promise<void>;

  /** Stop recording and clean up resources */
  stopRecording(): Promise<void>;

  /** Pause the current recording */
  pauseRecording(): Promise<void>;

  /** Resume a paused recording */
  resumeRecording(): Promise<void>;

  /** Check if currently recording */
  isRecording(): Promise<boolean>;

  /**
   * Register a callback for when a new audio chunk is ready.
   * Returns a function to unsubscribe.
   */
  onChunkReady(callback: (chunk: AudioChunk) => void): () => void;
}
