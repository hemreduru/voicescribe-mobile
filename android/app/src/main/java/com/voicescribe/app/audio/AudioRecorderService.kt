package com.voicescribe.app.audio

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.sqrt

class AudioRecorderService : Service() {

    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var recordingThread: Thread? = null
    private var wakeLock: PowerManager.WakeLock? = null
    
    companion object {
        private const val TAG = "AudioRecorderService"
        const val CHANNEL_ID = "VoiceScribeAudioServiceChannel"
        const val ACTION_CHUNK_READY = "com.voicescribe.app.CHUNK_READY"
        const val ACTION_AUDIO_LEVEL = "com.voicescribe.app.AUDIO_LEVEL"
        const val EXTRA_CHUNK_PATH = "chunk_path"
        const val EXTRA_AUDIO_LEVEL = "audio_level"

        private const val SAMPLE_RATE = 16000
        private const val CHANNELS = AudioFormat.CHANNEL_IN_MONO
        private const val ENCODING = AudioFormat.ENCODING_PCM_16BIT
        
        // Overlapping chunk strategy:
        // - Max chunk duration is 20 seconds
        // - At 18 seconds, start writing to the next chunk as well (2s overlap)
        // - VAD silence of 1.5s triggers early chunk end (if > MIN_CHUNK_DURATION_SEC)
        // - This overlap ensures words at chunk boundaries are not cut in half
        private const val MAX_CHUNK_DURATION_SEC = 20
        private const val OVERLAP_TRIGGER_SEC = 18       // Start overlap buffer at this point
        private const val OVERLAP_DURATION_SEC = 2        // Seconds of audio shared between chunks
        private const val MIN_CHUNK_DURATION_SEC = 2      // Minimum chunk length to avoid tiny chunks
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "VoiceScribe::AudioRecordWakeLock")
        wakeLock?.setReferenceCounted(false)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification()
        startForeground(1, notification)
        if (wakeLock?.isHeld != true) {
            wakeLock?.acquire()
        }
        
        startRecording()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    @SuppressLint("MissingPermission")
    private fun startRecording() {
        if (isRecording) return

        val minBufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNELS, ENCODING)
        if (minBufferSize <= 0) {
            stopSelf()
            return
        }
        val bufferSize = maxOf(minBufferSize, SAMPLE_RATE * 2) // 1 sec of audio

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            SAMPLE_RATE,
            CHANNELS,
            ENCODING,
            bufferSize
        )
        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
            audioRecord?.release()
            audioRecord = null
            stopSelf()
            return
        }

        audioRecord?.startRecording()
        isRecording = true

        recordingThread = Thread {
            val audioBuffer = ShortArray(bufferSize)
            val maxChunkSamples = SAMPLE_RATE * MAX_CHUNK_DURATION_SEC
            val overlapTriggerSamples = SAMPLE_RATE * OVERLAP_TRIGGER_SEC
            val minChunkSamples = SAMPLE_RATE * MIN_CHUNK_DURATION_SEC

            // Primary chunk buffer
            var chunkBuffer = ShortArray(maxChunkSamples)
            var currentSampleCount = 0

            // Overlap / next chunk buffer — starts collecting audio at OVERLAP_TRIGGER_SEC
            var nextChunkBuffer: ShortArray? = null
            var nextChunkSampleCount = 0
            var isOverlapping = false

            val vadManager = VADManager()

            while (isRecording) {
                val readSize = audioRecord?.read(audioBuffer, 0, audioBuffer.size) ?: 0
                if (readSize <= 0) continue

                broadcastAudioLevel(calculateNormalizedAudioLevel(audioBuffer, readSize))

                // ── 1. Write to the primary chunk buffer ──
                val primaryRemaining = maxChunkSamples - currentSampleCount
                val primaryCopy = minOf(readSize, primaryRemaining)
                if (primaryCopy > 0) {
                    System.arraycopy(audioBuffer, 0, chunkBuffer, currentSampleCount, primaryCopy)
                    currentSampleCount += primaryCopy
                }

                // ── 2. Start overlap when we pass the trigger point ──
                if (!isOverlapping && currentSampleCount >= overlapTriggerSamples) {
                    isOverlapping = true
                    nextChunkBuffer = ShortArray(maxChunkSamples)
                    nextChunkSampleCount = 0
                    Log.i(TAG, "Overlap started at ${currentSampleCount / SAMPLE_RATE}s")
                }

                // ── 3. If overlapping, also write to the next chunk buffer ──
                if (isOverlapping && nextChunkBuffer != null) {
                    val nextRemaining = maxChunkSamples - nextChunkSampleCount
                    val nextCopy = minOf(readSize, nextRemaining)
                    if (nextCopy > 0) {
                        System.arraycopy(audioBuffer, 0, nextChunkBuffer, nextChunkSampleCount, nextCopy)
                        nextChunkSampleCount += nextCopy
                    }
                }

                // ── 4. Decide whether to close the current chunk ──
                val hasMinDuration = currentSampleCount >= minChunkSamples
                val hasMaxDuration = currentSampleCount >= maxChunkSamples
                val shouldEndDueToSilence = vadManager.shouldEndChunk(audioBuffer, readSize)

                if (hasMaxDuration || (shouldEndDueToSilence && hasMinDuration)) {
                    val reason = if (hasMaxDuration) "max_duration" else "vad_silence"
                    val durationSec = currentSampleCount.toFloat() / SAMPLE_RATE
                    Log.i(TAG, "Closing chunk: reason=$reason duration=${String.format("%.1f", durationSec)}s overlap=$isOverlapping")

                    // Save & broadcast the completed primary chunk
                    saveAndBroadcastChunk(chunkBuffer, currentSampleCount)

                    // ── 5. Promote the overlap buffer (if any) to be the new primary ──
                    if (isOverlapping && nextChunkBuffer != null && nextChunkSampleCount > 0) {
                        chunkBuffer = nextChunkBuffer
                        currentSampleCount = nextChunkSampleCount
                    } else {
                        chunkBuffer = ShortArray(maxChunkSamples)
                        currentSampleCount = 0
                    }
                    nextChunkBuffer = null
                    nextChunkSampleCount = 0
                    isOverlapping = false
                    vadManager.reset()
                }
            }
            
            // Flush any remaining audio when recording is stopped
            if (currentSampleCount > 0) {
                saveAndBroadcastChunk(chunkBuffer, currentSampleCount)
            }
        }
        recordingThread?.start()
    }

    private fun saveAndBroadcastChunk(buffer: ShortArray, actualSize: Int) {
        if (actualSize <= 0) return
        
        val file = File(cacheDir, "chunk_${System.currentTimeMillis()}.wav")
        val actualBuffer = ShortArray(actualSize)
        System.arraycopy(buffer, 0, actualBuffer, 0, actualSize)
        
        val durationSec = actualSize.toFloat() / SAMPLE_RATE
        Log.i(TAG, "Saving chunk: ${file.name}, samples=$actualSize, duration=${String.format("%.2f", durationSec)}s")
        
        writeWavFile(file, actualBuffer, SAMPLE_RATE)
        
        val intent = Intent(ACTION_CHUNK_READY)
        intent.setPackage(packageName)
        intent.putExtra(EXTRA_CHUNK_PATH, file.absolutePath)
        intent.putExtra("chunk_duration", durationSec)
        sendBroadcast(intent)
        
        Log.i(TAG, "Chunk broadcast sent: ${file.name}")
    }

    private fun calculateNormalizedAudioLevel(buffer: ShortArray, length: Int): Float {
        if (length <= 0) {
            return 0f
        }

        var sumSquare = 0.0
        for (i in 0 until length) {
            val sample = buffer[i].toDouble()
            sumSquare += sample * sample
        }

        val rms = sqrt(sumSquare / length)
        return (rms / 1500.0).coerceIn(0.0, 1.0).toFloat()
    }

    private fun broadcastAudioLevel(level: Float) {
        val intent = Intent(ACTION_AUDIO_LEVEL)
        intent.setPackage(packageName)
        intent.putExtra(EXTRA_AUDIO_LEVEL, level)
        sendBroadcast(intent)
    }

    private fun writeWavFile(file: File, buffer: ShortArray, sampleRate: Int) {
        val byteBuffer = ByteBuffer.allocate(buffer.size * 2)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        for (s in buffer) {
            byteBuffer.putShort(s)
        }
        val byteData = byteBuffer.array()

        val outputStream = FileOutputStream(file)
        val totalDataLen = byteData.size + 36
        val totalAudioLen = byteData.size
        val channels = 1
        val byteRate = sampleRate * 2

        val header = ByteArray(44)
        header[0] = 'R'.code.toByte()
        header[1] = 'I'.code.toByte()
        header[2] = 'F'.code.toByte()
        header[3] = 'F'.code.toByte()
        header[4] = (totalDataLen and 0xff).toByte()
        header[5] = ((totalDataLen shr 8) and 0xff).toByte()
        header[6] = ((totalDataLen shr 16) and 0xff).toByte()
        header[7] = ((totalDataLen shr 24) and 0xff).toByte()
        header[8] = 'W'.code.toByte()
        header[9] = 'A'.code.toByte()
        header[10] = 'V'.code.toByte()
        header[11] = 'E'.code.toByte()
        header[12] = 'f'.code.toByte()
        header[13] = 'm'.code.toByte()
        header[14] = 't'.code.toByte()
        header[15] = ' '.code.toByte()
        header[16] = 16
        header[17] = 0
        header[18] = 0
        header[19] = 0
        header[20] = 1 // format = 1
        header[21] = 0
        header[22] = channels.toByte()
        header[23] = 0
        header[24] = (sampleRate and 0xff).toByte()
        header[25] = ((sampleRate shr 8) and 0xff).toByte()
        header[26] = ((sampleRate shr 16) and 0xff).toByte()
        header[27] = ((sampleRate shr 24) and 0xff).toByte()
        header[28] = (byteRate and 0xff).toByte()
        header[29] = ((byteRate shr 8) and 0xff).toByte()
        header[30] = ((byteRate shr 16) and 0xff).toByte()
        header[31] = ((byteRate shr 24) and 0xff).toByte()
        header[32] = (2 * channels).toByte()
        header[33] = 0
        header[34] = 16
        header[35] = 0
        header[36] = 'd'.code.toByte()
        header[37] = 'a'.code.toByte()
        header[38] = 't'.code.toByte()
        header[39] = 'a'.code.toByte()
        header[40] = (totalAudioLen and 0xff).toByte()
        header[41] = ((totalAudioLen shr 8) and 0xff).toByte()
        header[42] = ((totalAudioLen shr 16) and 0xff).toByte()
        header[43] = ((totalAudioLen shr 24) and 0xff).toByte()

        outputStream.write(header, 0, 44)
        outputStream.write(byteData)
        outputStream.close()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Audio Recording Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("VoiceScribe")
            .setContentText("Listening in background...")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .build()
    }

    override fun onDestroy() {
        isRecording = false
        recordingThread?.join(2000)
        if (recordingThread?.isAlive == true) {
            recordingThread?.interrupt()
        }
        audioRecord?.apply {
            try {
                if (recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                    stop()
                }
            } catch (_: IllegalStateException) {
                // no-op while tearing down
            }
            release()
        }
        audioRecord = null
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        super.onDestroy()
    }
}
