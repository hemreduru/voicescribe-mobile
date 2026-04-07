package com.voicescribe.app.audio

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.voicescribe.app.whisper.WhisperEngine
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Semaphore
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import kotlin.math.abs

class NativeAudioModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    companion object {
        private const val TAG = "NativeAudioModule"
        private const val EVENT_AUDIO_CHUNK_READY = "onAudioChunkReady"
        private const val EVENT_AUDIO_LEVEL = "onAudioLevel"
        private const val EVENT_TRANSCRIPT_READY = "onTranscriptReady"
        private const val EVENT_TRANSCRIPTION_ERROR = "onTranscriptionError"
        private const val EVENT_MODEL_DOWNLOAD_PROGRESS = "onModelDownloadProgress"

        // Number of parallel whisper workers. Each gets its own native context.
        // 2 workers = 2 parallel transcriptions while keeping RAM reasonable.
        private const val WHISPER_WORKER_COUNT = 2

        // Memory safety: skip transcription if heap usage exceeds this fraction.
        private const val MEMORY_PRESSURE_THRESHOLD = 0.82
    }

    // ── Executor pools ──
    // Single-thread for model download/init (avoids concurrent model file access)
    private val modelExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    // Fixed pool for parallel transcription (2 workers)
    private val transcribeExecutor: ExecutorService = Executors.newFixedThreadPool(WHISPER_WORKER_COUNT)

    // ── Whisper worker pool ──
    // Each worker has its own WhisperEngine (and thus its own native context).
    private val whisperWorkers = Array<WhisperEngine?>(WHISPER_WORKER_COUNT) { null }
    private val workerSemaphore = Semaphore(WHISPER_WORKER_COUNT)
    private val activeTranscriptions = AtomicInteger(0)

    @Volatile
    private var isReceiverRegistered = false

    @Volatile
    private var isWhisperModelLoaded = false

    // Path to the model file on disk (needed to init additional workers)
    @Volatile
    private var loadedModelPath: String? = null

    private val isShuttingDown = AtomicBoolean(false)

    // ── Broadcast receiver for audio chunks ──
    private val chunkReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                AudioRecorderService.ACTION_CHUNK_READY -> {
                    val chunkPath = intent.getStringExtra(AudioRecorderService.EXTRA_CHUNK_PATH)
                    chunkPath?.let {
                        sendEvent(EVENT_AUDIO_CHUNK_READY, it)
                        if (isWhisperModelLoaded) {
                            queueTranscription(it)
                        }
                    }
                }

                AudioRecorderService.ACTION_AUDIO_LEVEL -> {
                    val level = intent.getFloatExtra(AudioRecorderService.EXTRA_AUDIO_LEVEL, 0f)
                    val payload = Arguments.createMap()
                    payload.putDouble("level", level.toDouble())
                    payload.putDouble("timestamp", System.currentTimeMillis().toDouble())
                    sendEvent(EVENT_AUDIO_LEVEL, payload)
                }
            }
        }
    }

    override fun getName(): String = "NativeAudioModule"

    // ──────────────────────────────────────────────────────────────────────
    // Recording controls
    // ──────────────────────────────────────────────────────────────────────

    @ReactMethod
    fun startRecording() {
        registerChunkReceiverIfNeeded()
        val intent = Intent(reactApplicationContext, AudioRecorderService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            reactApplicationContext.startForegroundService(intent)
        } else {
            reactApplicationContext.startService(intent)
        }
    }

    @ReactMethod
    fun stopRecording() {
        val intent = Intent(reactApplicationContext, AudioRecorderService::class.java)
        reactApplicationContext.stopService(intent)
    }

    // ──────────────────────────────────────────────────────────────────────
    // Model management
    // ──────────────────────────────────────────────────────────────────────

    @ReactMethod
    fun loadWhisperModel(modelPath: String, promise: Promise) {
        modelExecutor.execute {
            try {
                val modelFile = File(modelPath)
                if (!modelFile.exists() || !modelFile.isFile) {
                    promise.reject("MODEL_NOT_FOUND", "Model file not found: $modelPath")
                    return@execute
                }

                val engine = getOrInitPrimaryEngine(modelPath)
                if (engine == null) {
                    isWhisperModelLoaded = false
                    promise.reject("MODEL_INIT_FAILED", "Failed to initialize whisper model")
                    return@execute
                }

                isWhisperModelLoaded = true
                loadedModelPath = modelPath
                promise.resolve(true)
            } catch (e: Exception) {
                isWhisperModelLoaded = false
                promise.reject("MODEL_INIT_ERROR", e.message, e)
            }
        }
    }

    @ReactMethod
    fun unloadWhisperModel(promise: Promise) {
        modelExecutor.execute {
            try {
                for (i in whisperWorkers.indices) {
                    whisperWorkers[i]?.freeModel()
                    whisperWorkers[i] = null
                }
                isWhisperModelLoaded = false
                loadedModelPath = null
                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("MODEL_FREE_ERROR", e.message, e)
            }
        }
    }

    @ReactMethod
    fun isWhisperModelLoaded(promise: Promise) {
        promise.resolve(isWhisperModelLoaded)
    }

    @ReactMethod
    fun ensureWhisperModel(modelUrl: String, fileName: String, promise: Promise) {
        modelExecutor.execute {
            try {
                val outputFile = modelFile(fileName)
                var downloaded = false
                val expectedSizeBytes = fetchRemoteContentLength(modelUrl)

                if (!isUsableModelFile(outputFile, expectedSizeBytes)) {
                    Log.i(
                        TAG,
                        "Model file missing/invalid. Re-downloading. path=${outputFile.absolutePath} size=${outputFile.length()} expected=$expectedSizeBytes"
                    )
                    downloadModelToFile(modelUrl, outputFile) { downloadedBytes, totalBytes ->
                        emitModelDownloadProgress(downloadedBytes, totalBytes)
                    }
                    downloaded = true
                }

                // Initialize primary worker (index 0)
                val engine = getOrInitPrimaryEngine(outputFile.absolutePath)
                if (engine == null) {
                    // Retry with clean download once
                    Log.w(TAG, "Model init failed. Retrying with clean download.")
                    if (outputFile.exists() && !outputFile.delete()) {
                        Log.w(TAG, "Failed to delete invalid model file before retry")
                    }
                    downloadModelToFile(modelUrl, outputFile) { downloadedBytes, totalBytes ->
                        emitModelDownloadProgress(downloadedBytes, totalBytes)
                    }
                    downloaded = true

                    val retryEngine = getOrInitPrimaryEngine(outputFile.absolutePath)
                    if (retryEngine == null) {
                        isWhisperModelLoaded = false
                        promise.reject(
                            "MODEL_INIT_FAILED",
                            "Failed to initialize whisper model after re-download (path=${outputFile.absolutePath}, size=${outputFile.length()})"
                        )
                        return@execute
                    }
                }

                isWhisperModelLoaded = true
                loadedModelPath = outputFile.absolutePath

                // Pre-initialize additional workers for parallel transcription
                initAdditionalWorkers(outputFile.absolutePath)

                val payload = Arguments.createMap()
                payload.putString("path", outputFile.absolutePath)
                payload.putBoolean("downloaded", downloaded)
                payload.putBoolean("loaded", true)
                promise.resolve(payload)
            } catch (e: Exception) {
                isWhisperModelLoaded = false
                promise.reject("MODEL_BOOTSTRAP_ERROR", e.message, e)
            }
        }
    }

    @ReactMethod
    fun downloadWhisperModel(modelUrl: String, fileName: String, promise: Promise) {
        modelExecutor.execute {
            try {
                val outputFile = modelFile(fileName)
                downloadModelToFile(modelUrl, outputFile) { downloadedBytes, totalBytes ->
                    emitModelDownloadProgress(downloadedBytes, totalBytes)
                }
                promise.resolve(outputFile.absolutePath)
            } catch (e: Exception) {
                promise.reject("MODEL_DOWNLOAD_ERROR", e.message, e)
            }
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Transcription
    // ──────────────────────────────────────────────────────────────────────

    @ReactMethod
    fun transcribeChunk(chunkPath: String, promise: Promise) {
        if (!isWhisperModelLoaded) {
            promise.reject("MODEL_NOT_LOADED", "Load a whisper model before transcribing")
            return
        }

        transcribeExecutor.execute {
            try {
                val transcript = transcribeWithWorker(chunkPath)
                promise.resolve(transcript)
            } catch (e: Exception) {
                promise.reject("TRANSCRIBE_ERROR", e.message, e)
            }
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Transcription state persistence
    // ──────────────────────────────────────────────────────────────────────

    @ReactMethod
    fun loadTranscriptionState(promise: Promise) {
        try {
            val file = transcriptionStateFile()
            if (!file.exists() || !file.isFile) {
                promise.resolve("")
                return
            }
            promise.resolve(file.readText())
        } catch (e: Exception) {
            promise.reject("TRANSCRIPTION_STATE_LOAD_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun saveTranscriptionState(stateJson: String, promise: Promise) {
        try {
            val file = transcriptionStateFile()
            file.writeText(stateJson)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("TRANSCRIPTION_STATE_SAVE_ERROR", e.message, e)
        }
    }

    // Required for React Native built-in NativeEventEmitter
    @ReactMethod
    fun addListener(eventName: String) {}

    @ReactMethod
    fun removeListeners(count: Int) {}

    // ──────────────────────────────────────────────────────────────────────
    // Lifecycle
    // ──────────────────────────────────────────────────────────────────────

    override fun invalidate() {
        isShuttingDown.set(true)
        unregisterChunkReceiverIfNeeded()

        for (i in whisperWorkers.indices) {
            try {
                whisperWorkers[i]?.freeModel()
            } catch (_: Exception) { }
            whisperWorkers[i] = null
        }
        isWhisperModelLoaded = false

        transcribeExecutor.shutdown()
        modelExecutor.shutdown()

        try {
            transcribeExecutor.awaitTermination(2, TimeUnit.SECONDS)
        } catch (_: InterruptedException) { }

        try {
            modelExecutor.awaitTermination(2, TimeUnit.SECONDS)
        } catch (_: InterruptedException) { }

        super.invalidate()
    }

    // ──────────────────────────────────────────────────────────────────────
    // Internal: Whisper worker pool
    // ──────────────────────────────────────────────────────────────────────

    /**
     * Get or initialize the primary whisper engine (worker 0).
     * Must be called from modelExecutor thread.
     */
    private fun getOrInitPrimaryEngine(modelPath: String): WhisperEngine? {
        val existing = whisperWorkers[0]
        if (existing != null && existing.isInitialized()) {
            return existing
        }

        val engine = WhisperEngine()
        val loaded = engine.initModel(modelPath)
        if (!loaded) return null

        whisperWorkers[0] = engine
        return engine
    }

    /**
     * Pre-initialize additional worker engines for parallel transcription.
     * Called after the primary engine is confirmed working.
     */
    private fun initAdditionalWorkers(modelPath: String) {
        for (i in 1 until WHISPER_WORKER_COUNT) {
            if (whisperWorkers[i]?.isInitialized() == true) continue
            try {
                val engine = WhisperEngine()
                val loaded = engine.initModel(modelPath)
                if (loaded) {
                    whisperWorkers[i] = engine
                    Log.i(TAG, "Initialized whisper worker $i")
                } else {
                    Log.w(TAG, "Failed to init whisper worker $i — will use primary only")
                }
            } catch (e: Exception) {
                Log.w(TAG, "Exception initializing whisper worker $i: ${e.message}")
            }
        }
    }

    /**
     * Acquire a worker slot (semaphore), then find an available engine and transcribe.
     * Falls back to primary engine if additional workers are not ready.
     */
    private fun transcribeWithWorker(chunkPath: String): String {
        val audioData = readWavPcm16AsFloatArray(chunkPath)
        if (audioData.isEmpty()) {
            Log.w(TAG, "Audio data is empty for: $chunkPath")
            return ""
        }
        val boostedAudio = applyAutoGain(audioData)
        Log.d(TAG, "Transcribing ${boostedAudio.size} audio samples (~${boostedAudio.size / 16000}s)")

        // Try to acquire a worker slot (non-blocking first, then blocking with timeout)
        val acquired = workerSemaphore.tryAcquire(5, TimeUnit.SECONDS)
        if (!acquired) {
            Log.w(TAG, "All whisper workers busy, using primary engine directly")
            // Fallback: use primary engine without semaphore (it's single-threaded per instance)
            val primary = whisperWorkers[0]
            if (primary != null && primary.isInitialized()) {
                return primary.transcribeAudio(boostedAudio).trim()
            }
            return ""
        }

        val activeCount = activeTranscriptions.incrementAndGet()
        Log.d(TAG, "Active transcriptions: $activeCount")

        try {
            // Find an available worker engine
            for (i in whisperWorkers.indices) {
                val engine = whisperWorkers[i]
                if (engine != null && engine.isInitialized()) {
                    return engine.transcribeAudio(boostedAudio).trim()
                }
            }
            // No initialized worker found — fallback to primary
            Log.w(TAG, "No initialized worker found, attempting lazy init")
            val modelPath = loadedModelPath
            if (modelPath != null) {
                val engine = WhisperEngine()
                if (engine.initModel(modelPath)) {
                    return engine.transcribeAudio(boostedAudio).trim()
                }
            }
            return ""
        } finally {
            activeTranscriptions.decrementAndGet()
            workerSemaphore.release()
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Internal: Transcription queue
    // ──────────────────────────────────────────────────────────────────────

    private fun queueTranscription(chunkPath: String) {
        if (isShuttingDown.get()) return

        // Memory pressure check before queueing
        if (isMemoryPressureHigh()) {
            Log.w(TAG, "Memory pressure high — skipping transcription for: $chunkPath")
            val payload = Arguments.createMap()
            payload.putString("chunkPath", chunkPath)
            payload.putString("message", "Transcription skipped due to memory pressure")
            sendEvent(EVENT_TRANSCRIPTION_ERROR, payload)
            return
        }

        Log.i(TAG, "Queueing transcription for chunk: $chunkPath")
        transcribeExecutor.execute {
            val startTime = System.currentTimeMillis()
            try {
                Log.i(TAG, "Starting transcription for: $chunkPath")
                val transcript = transcribeWithWorker(chunkPath)
                val duration = System.currentTimeMillis() - startTime
                Log.i(TAG, "Transcription completed in ${duration}ms, length=${transcript.length} chars")
                
                if (transcript.isNotBlank()) {
                    val payload = Arguments.createMap()
                    payload.putString("chunkPath", chunkPath)
                    payload.putString("text", transcript)
                    sendEvent(EVENT_TRANSCRIPT_READY, payload)
                    Log.i(TAG, "Transcript event sent: ${transcript.take(50)}...")
                } else {
                    Log.w(TAG, "Transcription result is blank for: $chunkPath")
                    val payload = Arguments.createMap()
                    payload.putString("chunkPath", chunkPath)
                    payload.putString("message", "No speech detected in audio chunk")
                    sendEvent(EVENT_TRANSCRIPTION_ERROR, payload)
                }
            } catch (e: Exception) {
                val duration = System.currentTimeMillis() - startTime
                Log.e(TAG, "Transcription failed after ${duration}ms: ${e.message}", e)
                val payload = Arguments.createMap()
                payload.putString("chunkPath", chunkPath)
                payload.putString("message", e.message ?: "Unknown transcription error")
                sendEvent(EVENT_TRANSCRIPTION_ERROR, payload)
            }
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Internal: Audio processing
    // ──────────────────────────────────────────────────────────────────────

    private fun applyAutoGain(input: FloatArray): FloatArray {
        var peak = 0f
        for (sample in input) {
            val a = abs(sample)
            if (a > peak) peak = a
        }

        if (peak <= 0f) return input

        val targetPeak = 0.6f
        val gain = (targetPeak / peak).coerceIn(1.0f, 8.0f)
        if (gain <= 1.05f) return input

        val out = FloatArray(input.size)
        for (i in input.indices) {
            val boosted = input[i] * gain
            out[i] = boosted.coerceIn(-1.0f, 1.0f)
        }
        Log.i(TAG, "Applied auto gain: peak=$peak gain=$gain")
        return out
    }

    private fun readWavPcm16AsFloatArray(chunkPath: String): FloatArray {
        val chunkFile = File(chunkPath)
        if (!chunkFile.exists() || !chunkFile.isFile) {
            throw IllegalArgumentException("Chunk file not found: $chunkPath")
        }

        val bytes = chunkFile.readBytes()
        if (bytes.size <= 44) return FloatArray(0)

        val pcmOffset = 44
        val sampleCount = (bytes.size - pcmOffset) / 2
        val out = FloatArray(sampleCount)

        var byteIndex = pcmOffset
        var sampleIndex = 0

        while (byteIndex + 1 < bytes.size && sampleIndex < sampleCount) {
            val lo = bytes[byteIndex].toInt() and 0xFF
            val hi = bytes[byteIndex + 1].toInt()
            val packed = (hi shl 8) or lo
            val signed = if (packed > Short.MAX_VALUE.toInt()) packed - 65536 else packed

            out[sampleIndex] = signed / 32768.0f

            sampleIndex += 1
            byteIndex += 2
        }

        return out
    }

    // ──────────────────────────────────────────────────────────────────────
    // Internal: Memory monitoring
    // ──────────────────────────────────────────────────────────────────────

    private fun isMemoryPressureHigh(): Boolean {
        val runtime = Runtime.getRuntime()
        val usedMB = (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024)
        val maxMB = runtime.maxMemory() / (1024 * 1024)
        val usageRatio = usedMB.toDouble() / maxMB.toDouble()

        if (usageRatio > MEMORY_PRESSURE_THRESHOLD) {
            Log.w(TAG, "Memory pressure: ${usedMB}MB / ${maxMB}MB (${String.format("%.0f", usageRatio * 100)}%)")
            return true
        }
        return false
    }

    // ──────────────────────────────────────────────────────────────────────
    // Internal: Model file management
    // ──────────────────────────────────────────────────────────────────────

    private fun modelsDirectory(): File {
        val modelsDir = File(reactApplicationContext.filesDir, "models")
        if (!modelsDir.exists()) {
            val created = modelsDir.mkdirs()
            if (!created) throw IllegalStateException("Failed to create models directory")
        }
        return modelsDir
    }

    private fun modelFile(fileName: String): File {
        val safeFileName = File(fileName).name
        if (safeFileName.isBlank()) throw IllegalArgumentException("Invalid model file name")
        return File(modelsDirectory(), safeFileName)
    }

    private fun emitModelDownloadProgress(downloadedBytes: Long, totalBytes: Long?) {
        val payload = Arguments.createMap()
        payload.putDouble("bytesDownloaded", downloadedBytes.toDouble())

        if (totalBytes != null && totalBytes > 0L) {
            val clampedPercent =
                ((downloadedBytes.toDouble() / totalBytes.toDouble()) * 100.0).coerceIn(0.0, 100.0)
            payload.putDouble("totalBytes", totalBytes.toDouble())
            payload.putDouble("percent", clampedPercent)
        } else {
            payload.putNull("totalBytes")
            payload.putNull("percent")
        }

        sendEvent(EVENT_MODEL_DOWNLOAD_PROGRESS, payload)
    }

    private fun downloadModelToFile(
        modelUrl: String,
        outputFile: File,
        onProgress: ((downloadedBytes: Long, totalBytes: Long?) -> Unit)? = null
    ) {
        var connection: HttpURLConnection? = null
        val tempFile = File(outputFile.absolutePath + ".part")
        try {
            if (tempFile.exists() && !tempFile.delete()) {
                throw IllegalStateException("Failed to clear temp model file: ${tempFile.absolutePath}")
            }

            connection = URL(modelUrl).openConnection() as HttpURLConnection
            connection.connectTimeout = 15000
            connection.readTimeout = 300000
            connection.requestMethod = "GET"
            connection.instanceFollowRedirects = true
            connection.setRequestProperty("User-Agent", "VoiceScribe-Android/1.0")
            connection.setRequestProperty("Accept", "*/*")

            if (connection.responseCode !in 200..299) {
                throw IllegalStateException(
                    "HTTP ${connection.responseCode}: ${connection.responseMessage}"
                )
            }

            val expectedBytes = connection.getHeaderFieldLong("Content-Length", -1L)
            val totalBytes = if (expectedBytes > 0L) expectedBytes else null
            onProgress?.invoke(0L, totalBytes)

            connection.inputStream.use { input ->
                FileOutputStream(tempFile).use { output ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    var downloadedBytes = 0L
                    var lastProgressEmitMs = 0L

                    while (true) {
                        val read = input.read(buffer)
                        if (read <= 0) break

                        output.write(buffer, 0, read)
                        downloadedBytes += read.toLong()

                        val nowMs = System.currentTimeMillis()
                        val shouldEmit =
                            nowMs - lastProgressEmitMs >= 250L ||
                                (totalBytes != null && downloadedBytes >= totalBytes)

                        if (shouldEmit) {
                            onProgress?.invoke(downloadedBytes, totalBytes)
                            lastProgressEmitMs = nowMs
                        }
                    }
                }
            }

            if (expectedBytes > 0 && tempFile.length() != expectedBytes) {
                throw IllegalStateException(
                    "Downloaded ${tempFile.length()} bytes, expected $expectedBytes bytes"
                )
            }

            if (outputFile.exists() && !outputFile.delete()) {
                throw IllegalStateException("Failed to replace model file: ${outputFile.absolutePath}")
            }

            if (!tempFile.renameTo(outputFile)) {
                throw IllegalStateException("Failed to finalize model file: ${outputFile.absolutePath}")
            }

            onProgress?.invoke(outputFile.length(), totalBytes ?: outputFile.length())
        } finally {
            connection?.disconnect()
            if (tempFile.exists()) tempFile.delete()
        }
    }

    private fun fetchRemoteContentLength(modelUrl: String): Long? {
        var connection: HttpURLConnection? = null
        return try {
            connection = URL(modelUrl).openConnection() as HttpURLConnection
            connection.requestMethod = "HEAD"
            connection.connectTimeout = 15000
            connection.readTimeout = 15000
            connection.instanceFollowRedirects = true
            connection.setRequestProperty("User-Agent", "VoiceScribe-Android/1.0")
            connection.setRequestProperty("Accept", "*/*")

            if (connection.responseCode in 200..299) {
                val length = connection.getHeaderFieldLong("Content-Length", -1L)
                if (length > 0L) length else null
            } else null
        } catch (_: Exception) {
            null
        } finally {
            connection?.disconnect()
        }
    }

    private fun isUsableModelFile(file: File, expectedSizeBytes: Long?): Boolean {
        if (!file.exists() || !file.isFile) return false
        val actualSize = file.length()
        if (actualSize <= 0L) return false
        if (expectedSizeBytes != null && expectedSizeBytes > 0L) {
            return actualSize == expectedSizeBytes
        }
        return actualSize >= 1024L * 1024L
    }

    private fun transcriptionStateFile(): File {
        val stateDir = File(reactApplicationContext.filesDir, "state")
        if (!stateDir.exists()) {
            val created = stateDir.mkdirs()
            if (!created) throw IllegalStateException("Failed to create state directory")
        }
        return File(stateDir, "transcripts.json")
    }

    // ──────────────────────────────────────────────────────────────────────
    // Internal: Broadcast receiver management
    // ──────────────────────────────────────────────────────────────────────

    private fun registerChunkReceiverIfNeeded() {
        if (isReceiverRegistered) return

        val filter = IntentFilter(AudioRecorderService.ACTION_CHUNK_READY).apply {
            addAction(AudioRecorderService.ACTION_AUDIO_LEVEL)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            reactApplicationContext.registerReceiver(
                chunkReceiver,
                filter,
                Context.RECEIVER_NOT_EXPORTED
            )
        } else {
            reactApplicationContext.registerReceiver(chunkReceiver, filter)
        }
        isReceiverRegistered = true
    }

    private fun unregisterChunkReceiverIfNeeded() {
        if (!isReceiverRegistered) return
        try {
            reactApplicationContext.unregisterReceiver(chunkReceiver)
        } catch (_: Exception) { }
        finally {
            isReceiverRegistered = false
        }
    }

    private fun sendEvent(eventName: String, data: Any) {
        reactApplicationContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, data)
    }
}
