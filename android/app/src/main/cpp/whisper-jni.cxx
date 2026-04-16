#include <jni.h>
#include <string>
#include <vector>
#include <map>
#include <mutex>
#include <android/log.h>
#include "whisper.h"

#define TAG "VoiceScribeJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// ──────────────────────────────────────────────────────────────────────────
// Multi-context pool: each WhisperEngine instance in Kotlin has a unique ID
// that maps to a native whisper_context* pointer.
// This allows parallel transcription without SIGSEGV races.
// ──────────────────────────────────────────────────────────────────────────

static std::mutex g_context_mutex;
static std::map<jlong, whisper_context*> g_context_pool;
static jlong g_next_context_id = 0;

/**
 * Create a new whisper context from a model file.
 * Returns a unique context ID >= 0 on success, or -1 on failure.
 */
extern "C" JNIEXPORT jlong JNICALL
Java_com_voicescribe_app_whisper_WhisperEngine_nativeInitContext(
    JNIEnv *env, jobject thiz, jstring model_path) {
    
    const char *path = env->GetStringUTFChars(model_path, nullptr);
    
    struct whisper_context_params cparams = whisper_context_default_params();
    whisper_context* ctx = whisper_init_from_file_with_params(path, cparams);
    
    env->ReleaseStringUTFChars(model_path, path);
    
    if (ctx == nullptr) {
        LOGE("Failed to initialize whisper.cpp context from: %s", path);
        return -1;
    }
    
    std::lock_guard<std::mutex> lock(g_context_mutex);
    jlong context_id = g_next_context_id++;
    g_context_pool[context_id] = ctx;
    
    LOGI("Created whisper context: id=%lld path=%s", (long long)context_id, path);
    return context_id;
}

/**
 * Transcribe audio using the whisper context identified by context_id.
 * Thread-safe per context because each Kotlin WhisperEngine instance
 * owns a unique context ID.
 */
extern "C" JNIEXPORT jstring JNICALL
Java_com_voicescribe_app_whisper_WhisperEngine_nativeTranscribe(
    JNIEnv *env, jobject thiz, jlong context_id, jfloatArray audio_data) {
    
    whisper_context* ctx = nullptr;
    {
        std::lock_guard<std::mutex> lock(g_context_mutex);
        auto it = g_context_pool.find(context_id);
        if (it == g_context_pool.end()) {
            LOGE("Invalid context_id: %lld", (long long)context_id);
            return env->NewStringUTF("");
        }
        ctx = it->second;
    }
    
    if (ctx == nullptr) {
        LOGE("Context is null for id=%lld", (long long)context_id);
        return env->NewStringUTF("");
    }
    
    jsize len = env->GetArrayLength(audio_data);
    jfloat *body = env->GetFloatArrayElements(audio_data, 0);
    
    // Whisper full parametrization — optimized for mobile
    whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    wparams.print_progress   = false;
    wparams.print_special    = false;
    wparams.print_realtime   = false;
    wparams.print_timestamps = false;
    wparams.translate        = false;  // Keep original language
    wparams.language         = "auto"; // Auto-detect language from speech
    // Increased from 2 to 4 threads for faster inference on modern mid/high-end devices
    wparams.n_threads        = 4;
    
    if (whisper_full(ctx, wparams, body, len) != 0) {
        LOGE("whisper_full failed for context_id=%lld", (long long)context_id);
        env->ReleaseFloatArrayElements(audio_data, body, 0);
        return env->NewStringUTF("");
    }
    
    env->ReleaseFloatArrayElements(audio_data, body, 0);
    
    // Extract text from the segments
    std::string resultText = "";
    int n_segments = whisper_full_n_segments(ctx);
    for (int i = 0; i < n_segments; ++i) {
        const char* text = whisper_full_get_segment_text(ctx, i);
        resultText += text;
    }
    
    return env->NewStringUTF(resultText.c_str());
}

/**
 * Free the native whisper context identified by context_id.
 */
extern "C" JNIEXPORT void JNICALL
Java_com_voicescribe_app_whisper_WhisperEngine_nativeFreeContext(
    JNIEnv *env, jobject thiz, jlong context_id) {
    
    whisper_context* ctx = nullptr;
    {
        std::lock_guard<std::mutex> lock(g_context_mutex);
        auto it = g_context_pool.find(context_id);
        if (it != g_context_pool.end()) {
            ctx = it->second;
            g_context_pool.erase(it);
        }
    }
    
    if (ctx != nullptr) {
        whisper_free(ctx);
        LOGI("Freed whisper context: id=%lld", (long long)context_id);
    }
}

// ──────────────────────────────────────────────────────────────────────────
// Legacy single-context JNI methods (kept for backward compatibility)
// ──────────────────────────────────────────────────────────────────────────

static whisper_context * legacy_ctx = nullptr;

extern "C" JNIEXPORT jboolean JNICALL
Java_com_voicescribe_app_whisper_WhisperEngine_initModel_1legacy(
    JNIEnv *env, jobject thiz, jstring model_path) {
    
    if (legacy_ctx != nullptr) {
        whisper_free(legacy_ctx);
        legacy_ctx = nullptr;
    }
    
    const char *path = env->GetStringUTFChars(model_path, nullptr);
    struct whisper_context_params cparams = whisper_context_default_params();
    legacy_ctx = whisper_init_from_file_with_params(path, cparams);
    env->ReleaseStringUTFChars(model_path, path);
    
    if (legacy_ctx == nullptr) {
        LOGE("Failed to initialize legacy whisper.cpp model");
        return JNI_FALSE;
    }
    LOGI("Successfully initialized legacy whisper.cpp");
    return JNI_TRUE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_voicescribe_app_whisper_WhisperEngine_transcribeAudio_1legacy(
    JNIEnv *env, jobject thiz, jfloatArray audio_data) {
    
    if (legacy_ctx == nullptr) {
        LOGE("Legacy whisper context is null, skipping transcription");
        return env->NewStringUTF("");
    }
    
    jsize len = env->GetArrayLength(audio_data);
    jfloat *body = env->GetFloatArrayElements(audio_data, 0);
    
    whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    wparams.print_progress   = false;
    wparams.print_special    = false;
    wparams.print_realtime   = false;
    wparams.print_timestamps = false;
    wparams.translate        = false;
    wparams.language         = "auto";
    wparams.n_threads        = 4;
    
    if (whisper_full(legacy_ctx, wparams, body, len) != 0) {
        LOGE("whisper_full failed (legacy)");
        env->ReleaseFloatArrayElements(audio_data, body, 0);
        return env->NewStringUTF("");
    }
    
    env->ReleaseFloatArrayElements(audio_data, body, 0);
    
    std::string resultText = "";
    int n_segments = whisper_full_n_segments(legacy_ctx);
    for (int i = 0; i < n_segments; ++i) {
        const char * text = whisper_full_get_segment_text(legacy_ctx, i);
        resultText += text;
    }
    
    return env->NewStringUTF(resultText.c_str());
}

extern "C" JNIEXPORT void JNICALL
Java_com_voicescribe_app_whisper_WhisperEngine_freeModel_1legacy(
    JNIEnv *env, jobject thiz) {
    
    if (legacy_ctx != nullptr) {
        whisper_free(legacy_ctx);
        legacy_ctx = nullptr;
    }
}
