/**
 * Native speaker recognition module interface.
 * Bridges to lightweight speaker embedding model (e.g., ECAPA-TDNN).
 */

export interface SpeakerEmbedding {
  /** Speaker profile identifier */
  profileId: string;
  /** Speaker display name */
  name: string;
  /** 192-dimensional embedding vector */
  embedding: number[];
}

export interface SpeakerIdentifyResult {
  /** Matched speaker profile ID, or null if unknown */
  profileId: string | null;
  /** Matched speaker name, or 'Unknown' */
  name: string;
  /** Similarity score (0.0 - 1.0) */
  similarity: number;
  /** Whether the match exceeds the threshold */
  isMatch: boolean;
}

export interface NativeSpeakerModule {
  /**
   * Generate a speaker embedding from audio data.
   * @param audioData - Base64 encoded PCM audio (2-3 seconds recommended)
   * @returns 192-dimensional embedding vector
   */
  generateEmbedding(audioData: string): Promise<number[]>;

  /**
   * Enroll a new speaker profile.
   * @param name - Display name for the speaker
   * @param audioSamples - Array of base64 PCM audio samples
   * @returns The created speaker profile ID
   */
  enrollSpeaker(name: string, audioSamples: string[]): Promise<string>;

  /**
   * Identify the speaker in an audio sample.
   * @param audioData - Base64 encoded PCM audio
   * @param threshold - Similarity threshold (default: 0.7)
   */
  identifySpeaker(
    audioData: string,
    threshold?: number,
  ): Promise<SpeakerIdentifyResult>;

  /** Get all enrolled speaker profiles */
  getProfiles(): Promise<SpeakerEmbedding[]>;

  /** Delete a speaker profile */
  deleteProfile(profileId: string): Promise<void>;

  /** Check if the speaker model is loaded */
  isModelLoaded(): Promise<boolean>;

  /** Load the speaker embedding model */
  loadModel(): Promise<void>;
}
