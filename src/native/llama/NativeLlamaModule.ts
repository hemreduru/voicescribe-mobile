/**
 * Native llama.cpp module interface.
 * Bridges to C++ LLM inference for on-device summarization.
 */

export interface LlamaGenerationConfig {
  /** Maximum tokens to generate */
  maxTokens?: number;
  /** Temperature for sampling (0.0 - 2.0) */
  temperature?: number;
  /** Top-p (nucleus) sampling */
  topP?: number;
  /** System prompt prepended to input */
  systemPrompt?: string;
}

export interface LlamaModelInfo {
  /** Model identifier */
  modelId: string;
  /** Model file path on device */
  path: string;
  /** Whether the model is currently loaded */
  isLoaded: boolean;
  /** Model file size in bytes */
  sizeBytes: number;
  /** Context window size in tokens */
  contextSize: number;
}

export interface NativeLlamaModule {
  /** Load a GGUF model into memory */
  loadModel(modelPath: string, contextSize?: number): Promise<void>;

  /** Unload the current model to free memory */
  unloadModel(): Promise<void>;

  /** Check if a model is currently loaded */
  isModelLoaded(): Promise<boolean>;

  /**
   * Generate text from a prompt.
   * @param prompt - Input text to process
   * @param config - Generation configuration
   * @returns Generated text
   */
  generate(prompt: string, config?: LlamaGenerationConfig): Promise<string>;

  /**
   * Generate with streaming output.
   * @param prompt - Input text
   * @param config - Generation config
   * @param onToken - Callback for each generated token
   */
  generateStream(
    prompt: string,
    config: LlamaGenerationConfig | undefined,
    onToken: (token: string) => void,
  ): Promise<string>;

  /** Get info about available models on device */
  getAvailableModels(): Promise<LlamaModelInfo[]>;
}
