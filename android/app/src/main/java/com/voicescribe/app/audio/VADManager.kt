package com.voicescribe.app.audio

import kotlin.math.sqrt

class VADManager(private val threshold: Int = 350) {

    private var silenceStartTime: Long = 0
    private var lastVoiceDetectedTime: Long = System.currentTimeMillis()
    
    companion object {
        // 1.5 seconds of continuous silence triggers chunk end.
        // Slightly longer than 1.2s to reduce false positives from brief pauses.
        const val SILENCE_DURATION_MS = 1500L
    }

    /**
     * Calculates the RMS (Root Mean Square) amplitude of an audio buffer
     * and returns true if it exceeds the silence threshold.
     * Threshold set to 350 to detect normal speech levels without
     * being too sensitive to ambient noise.
     */
    fun isVoiceDetected(buffer: ShortArray, length: Int): Boolean {
        if (length == 0) return false

        var sumSquare = 0.0
        for (i in 0 until length) {
            val sample = buffer[i].toDouble()
            sumSquare += (sample * sample)
        }

        val rms = sqrt(sumSquare / length)
        return rms > threshold
    }
    
    /**
     * Processes audio buffer and tracks silence duration.
     * Returns true if a chunk should end (1.5s silence detected).
     */
    fun shouldEndChunk(buffer: ShortArray, length: Int): Boolean {
        val currentTime = System.currentTimeMillis()
        val hasVoice = isVoiceDetected(buffer, length)
        
        if (hasVoice) {
            lastVoiceDetectedTime = currentTime
            silenceStartTime = 0
            return false
        }
        
        // Silence detected
        if (silenceStartTime == 0L) {
            silenceStartTime = currentTime
        }
        
        val silenceDuration = currentTime - silenceStartTime
        return silenceDuration >= SILENCE_DURATION_MS
    }
    
    /**
     * Resets silence tracking (call when chunk is saved).
     */
    fun reset() {
        silenceStartTime = 0
        lastVoiceDetectedTime = System.currentTimeMillis()
    }
}
