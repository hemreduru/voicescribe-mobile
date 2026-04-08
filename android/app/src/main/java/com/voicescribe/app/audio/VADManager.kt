package com.voicescribe.app.audio

import android.util.Log
import kotlin.math.sqrt

class VADManager {
    companion object {
        private const val TAG = "VADManager"
        private const val MAX_SILENCE_DURATION_SEC = 1.5f
        private const val SAMPLE_RATE = 16000
        private val MAX_SILENCE_SAMPLES = (SAMPLE_RATE * MAX_SILENCE_DURATION_SEC).toInt()
        
        // Define an absolute minimum and maximum for the noise floor
        private const val MIN_NOISE_FLOOR = 0.01f
        private const val MAX_NOISE_FLOOR = 0.15f
    }

    private var silenceSampleCount = 0
    private var systemTotalSamples = 0
    
    // Dynamic noise floor tracking
    private var noiseFloor = 0.03f 

    fun shouldEndChunk(audioBuffer: ShortArray, readSize: Int): Boolean {
        if (readSize <= 0) return false

        systemTotalSamples += readSize
        val level = calculateRMS(audioBuffer, readSize)

        // Track the noise floor dynamically.
        // We track downward quickly to capture silence.
        // We track upward very slowly, so sustained speech doesn't immediately become the "noise floor".
        if (level < noiseFloor) {
            noiseFloor = (noiseFloor * 0.8f) + (level * 0.2f)
        } else {
            noiseFloor = (noiseFloor * 0.999f) + (level * 0.001f)
        }
        
        // Clamp the noise floor to sane boundaries
        noiseFloor = noiseFloor.coerceIn(MIN_NOISE_FLOOR, MAX_NOISE_FLOOR)

        // The voice threshold is slightly above the current estimated noise floor
        val threshold = noiseFloor + 0.04f

        if (level < threshold) {
            silenceSampleCount += readSize
        } else {
            silenceSampleCount = 0
        }

        if (silenceSampleCount >= MAX_SILENCE_SAMPLES) {
            Log.i(TAG, "VAD triggered: > ${MAX_SILENCE_DURATION_SEC}s silence. Level: $level, Estimated NoiseFloor: $noiseFloor")
            return true
        }

        return false
    }

    fun reset() {
        silenceSampleCount = 0
        // We explicitly DO NOT reset systemTotalSamples or noiseFloor here, 
        // because the environment hasn't changed just because a chunk ended.
    }

    private fun calculateRMS(buffer: ShortArray, length: Int): Float {
        var sumSquare = 0.0
        for (i in 0 until length) {
            val sample = buffer[i].toDouble()
            sumSquare += sample * sample
        }
        val rms = sqrt(sumSquare / length)
        return (rms / 1500.0).coerceIn(0.0, 1.0).toFloat()
    }
}
