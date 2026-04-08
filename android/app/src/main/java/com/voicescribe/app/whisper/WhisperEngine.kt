package com.voicescribe.app.whisper

import android.util.Log

/**
 * Thread-safe wrapper around whisper.cpp JNI.
 *
 * Each instance holds its own native whisper_context pointer (managed by
 * a per-instance ID in the C++ layer).  This allows multiple WhisperEngine
 * instances to run transcriptions in parallel without SIGSEGV races.
 */
class WhisperEngine {
    companion object {
        private const val TAG = "WhisperEngine"

        init {
            System.loadLibrary("voicescribe-whisper")
        }
    }

    // Unique id that maps to a native whisper_context* in the C++ context pool.
    private var contextId: Long = -1

    @Volatile
    private var initialized = false

    val isBusy = java.util.concurrent.atomic.AtomicBoolean(false)

    /**
     * Initialize a whisper model, returning true on success.
     * Safe to call multiple times — will free any previous context first.
     */
    @Synchronized
    fun initModel(modelPath: String): Boolean {
        if (initialized && contextId >= 0) {
            nativeFreeContext(contextId)
            contextId = -1
            initialized = false
        }
        val id = nativeInitContext(modelPath)
        if (id < 0) {
            Log.e(TAG, "Failed to initialize whisper context for: $modelPath")
            return false
        }
        contextId = id
        initialized = true
        Log.i(TAG, "Whisper context initialized: id=$id path=$modelPath")
        return true
    }

    /**
     * Transcribe float PCM audio data.  Thread-safe per instance because
     * each instance owns a separate native context.
     */
    @Synchronized
    fun transcribeAudio(audioData: FloatArray): String {
        val id = contextId
        if (!initialized || id < 0) {
            Log.e(TAG, "transcribeAudio called but context is not initialized")
            return ""
        }
        return nativeTranscribe(id, audioData)
    }

    /**
     * Free the native context and release memory.
     */
    @Synchronized
    fun freeModel() {
        if (initialized && contextId >= 0) {
            nativeFreeContext(contextId)
            Log.i(TAG, "Whisper context freed: id=$contextId")
            contextId = -1
            initialized = false
        }
    }

    fun isInitialized(): Boolean = initialized

    // ── JNI declarations ──

    /** Create a new native whisper context from a model file. Returns context ID >= 0 on success. */
    private external fun nativeInitContext(modelPath: String): Long

    /** Transcribe audio using the context identified by [contextId]. */
    private external fun nativeTranscribe(contextId: Long, audioData: FloatArray): String

    /** Free the native context identified by [contextId]. */
    private external fun nativeFreeContext(contextId: Long)

    // Legacy JNI — kept for backward compatibility but no longer used internally.
    external fun initModel_legacy(modelPath: String): Boolean
    external fun transcribeAudio_legacy(audioData: FloatArray): String
    external fun freeModel_legacy()
}
