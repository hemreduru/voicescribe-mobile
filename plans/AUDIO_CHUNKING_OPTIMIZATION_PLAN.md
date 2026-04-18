# VoiceScribe Audio Chunking & Transcription Optimization Plan

**Tarih:** 2026-04-07  
**Hedef:** Chunk'larda kelime kesintisi ve yavaş transkripsiyon sorunlarını çözümlemek

---

## 🎯 Tespit Edilen Sorunlar

### Problem 1: Yavaş Transkripsiyon (Kayıt durduktan sonra)
**Mevcut Durum:**
- Kayıt bitince son chunk flush ediliyor
- Whisper.cpp tek thread'de sırayla işliyor (`SingleThreadExecutor`)
- Her chunk sırayla transcribe ediliyor → biriken queue yüzünden gecikmeli sonuç

**Kök Neden:**
- `NativeAudioModule.kt:28` - `Executors.newSingleThreadExecutor()` kullanılıyor
- Chunk'lar sırayla işlendiği için son chunk'ın transcription'ını beklemek zorunda kalıyoruz
- Model çok büyükse (örn. base/small/medium) inference süresi uzun

---

### Problem 2: Kelime Kesintisi (Chunk ortasında kelime kesilmesi)
**Mevcut Durum:**
- Chunk'lar VAD (Voice Activity Detection) veya max 8 saniyelik sürelerle kapanıyor
- Chunk bittiğinde kelime ortasında kesilme olabiliyor
- Overlap yok → her chunk bağımsız → context kaybı

**Örnek:**
```
Chunk 1: "Bugün hava çok gü..." (8 saniye doldu, kapandı)
Chunk 2: "zel ve ben dışarı..." (yeni chunk başladı)
```

**Senin Önerdiğin Çözüm:**
- 18. saniyeye geldiğinde yeni chunk'ı **overlap olarak başlat**
- 20. saniyede eski chunk'ı kapat
- 2 saniyelik overlap kelimelerin bütünlüğünü korur

---

### Problem 3: Uygulama Crash'leri
**Olası Nedenler:**
1. **whisper.cpp thread-safety:** `whisper_full()` aynı context'te concurrent çağrılırsa SIGSEGV
2. **Memory pressure:** Whisper model büyükse + çok chunk birikirse OOM
3. **Wake lock leak:** Service düzgün temizlenmezse wake lock sızıntısı
4. **Audio buffer overflow:** Chunk buffer taşarsa undefined behavior

---

## ✅ Önerilen Çözümler

### Çözüm 1: Transkripsiyon Hızlandırma

#### Yaklaşım A: Parallel Chunk Processing (Önerilen) ⭐
**Strateji:**
- Her chunk için **yeni bir Whisper context** oluştur (isolate)
- Chunk'ları paralel işle (2-4 thread pool)
- Her context bağımsız → thread-safe

**Değişiklikler:**
```kotlin
// NativeAudioModule.kt
- private val transcribeExecutor = Executors.newSingleThreadExecutor()
+ private val transcribeExecutor = Executors.newFixedThreadPool(3) // 3 parallel işlem
+ private val whisperContextPool = ConcurrentHashMap<String, WhisperEngine>()

private fun queueTranscription(chunkPath: String) {
    transcribeExecutor.execute {
        val engine = getOrCreateWhisperEngine() // Pool'dan al veya yeni oluştur
        val transcript = engine.transcribeAudio(audioData)
        // ...
        returnWhisperEngine(engine) // Pool'a geri ver
    }
}
```

**Avantajlar:**
- ✅ 3x daha hızlı (3 chunk paralel)
- ✅ Kayıt durduktan sonra final chunk hemen işlenir
- ✅ Thread-safe (her context izole)

**Dezavantajlar:**
- ❌ Daha fazla RAM kullanımı (3x model)
- ❌ CPU/termal basınç artabilir

---

#### Yaklaşım B: Streaming Transcription ⚡ (Experimental)
**Strateji:**
- Chunk'ları küçült (2-3 saniye)
- Her chunk geldiğinde hemen transcribe et
- Kullanıcı **live preview** görsün

**Avantajlar:**
- ✅ Real-time feedback
- ✅ Kayıt bitiminde tüm transcription hazır

**Dezavantajlar:**
- ❌ Daha fazla Whisper çağrısı → batarya tüketimi
- ❌ Küçük chunk'larda context kaybı

---

#### Yaklaşım C: Daha Küçük Model (En Kolay) 🚀
**Strateji:**
- `ggml-base.bin` yerine `ggml-tiny.bin` kullan
- Model boyutu: 75MB → 35MB
- Inference hızı: ~3-5x daha hızlı

**Değişiklikler:**
```kotlin
// RecordingScreen.tsx veya bootstrap config
- const MODEL_URL = "https://huggingface.co/.../ggml-base.bin"
+ const MODEL_URL = "https://huggingface.co/.../ggml-tiny.bin"
```

**Avantajlar:**
- ✅ Çok hızlı inference
- ✅ Minimum kod değişikliği
- ✅ Düşük RAM kullanımı

**Dezavantajlar:**
- ❌ Doğruluk biraz düşer (özellikle gürültülü ortamlarda)

---

### Çözüm 2: Overlapping Chunk Strategy (Senin Önerine Göre)

#### Yeni Chunk Mekanizması
```kotlin
// AudioRecorderService.kt
private const val MAX_CHUNK_DURATION_SEC = 20
private const val OVERLAP_DURATION_SEC = 2
private const val CHUNK_SPLIT_TRIGGER_SEC = 18

// Chunk state
private var currentChunkBuffer = ShortArray(maxChunkSamples)
private var nextChunkBuffer: ShortArray? = null
private var currentSampleCount = 0
private var nextChunkStartSample = 0
private var isOverlapping = false

while (isRecording) {
    val readSize = audioRecord?.read(audioBuffer, 0, audioBuffer.size) ?: 0
    if (readSize > 0) {
        // 1. Ana chunk'a ekle
        System.arraycopy(audioBuffer, 0, currentChunkBuffer, currentSampleCount, readSize)
        currentSampleCount += readSize
        
        val elapsedSec = currentSampleCount / SAMPLE_RATE
        
        // 2. 18. saniyeye geldiğinde overlap chunk'ı başlat
        if (elapsedSec >= CHUNK_SPLIT_TRIGGER_SEC && !isOverlapping) {
            isOverlapping = true
            nextChunkBuffer = ShortArray(maxChunkSamples)
            nextChunkStartSample = 0
            Log.i(TAG, "Starting overlap chunk at ${elapsedSec}s")
        }
        
        // 3. Overlap aktifse yeni chunk'a da yaz
        if (isOverlapping && nextChunkBuffer != null) {
            System.arraycopy(audioBuffer, 0, nextChunkBuffer!!, nextChunkStartSample, readSize)
            nextChunkStartSample += readSize
        }
        
        // 4. VAD silence detection
        val shouldEndDueToSilence = vadManager.shouldEndChunk(audioBuffer, readSize)
        val hasMinDuration = elapsedSec >= MIN_CHUNK_DURATION_SEC
        
        // 5. Chunk'ı kapat:
        //    - 20 saniyeye ulaştı
        //    - VEYA 1.2s sessizlik + minimum süre geçti
        if (elapsedSec >= MAX_CHUNK_DURATION_SEC || (shouldEndDueToSilence && hasMinDuration)) {
            // Ana chunk'ı kaydet
            saveAndBroadcastChunk(currentChunkBuffer, currentSampleCount)
            
            // Eğer overlap başlamışsa, onu yeni ana chunk yap
            if (isOverlapping && nextChunkBuffer != null) {
                currentChunkBuffer = nextChunkBuffer!!
                currentSampleCount = nextChunkStartSample
                nextChunkBuffer = null
                nextChunkStartSample = 0
                isOverlapping = false
            } else {
                // Overlap yoksa sıfırdan başla
                currentChunkBuffer = ShortArray(maxChunkSamples)
                currentSampleCount = 0
            }
            
            chunkStartTime = System.currentTimeMillis()
            vadManager.reset()
        }
    }
}
```

#### Overlap Stratejisi Görselleştirme
```
Zaman:    0s -------- 10s -------- 18s -- 20s -------- 30s -------- 38s -- 40s
          |                         |     |                         |     |
Chunk 1:  [========== konuşma ===== overlap ====]
Chunk 2:                            [==== overlap ==== konuşma ====]
                                    ^                               ^
                                    18s'de başla                    20s'de bitir
                                    (2s overlap)
```

**Avantajlar:**
- ✅ Kelime kesintisi %90 azalır
- ✅ Context korunur (2 saniye overlap)
- ✅ VAD silence detection hala çalışır (erken kapanma)

**Dezavantajlar:**
- ❌ Overlap bölgede duplicate text olabilir → post-processing gerekli
- ❌ Biraz daha fazla storage (overlap audio)

---

### Çözüm 3: Crash Prevention

#### 1. Thread-Safe Whisper Context
```kotlin
// NativeAudioModule.kt
private val whisperEngineLock = ReentrantLock()

private fun transcribeChunkInternal(chunkPath: String): String {
    whisperEngineLock.lock()
    try {
        val audioData = readWavPcm16AsFloatArray(chunkPath)
        if (audioData.isEmpty()) {
            return ""
        }
        val boostedAudio = applyAutoGain(audioData)
        return whisperEngine.transcribeAudio(boostedAudio).trim()
    } finally {
        whisperEngineLock.unlock()
    }
}
```

#### 2. Memory Monitoring
```kotlin
// NativeAudioModule.kt
private fun queueTranscription(chunkPath: String) {
    val runtime = Runtime.getRuntime()
    val usedMemoryMB = (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024)
    val maxMemoryMB = runtime.maxMemory() / (1024 * 1024)
    
    if (usedMemoryMB > maxMemoryMB * 0.85) {
        Log.w(TAG, "Memory pressure detected ($usedMemoryMB MB / $maxMemoryMB MB), skipping transcription")
        return
    }
    
    transcribeExecutor.execute {
        // ... transcription logic
    }
}
```

#### 3. Wake Lock Leak Fix (Zaten doğru görünüyor)
```kotlin
// AudioRecorderService.kt - onDestroy
override fun onDestroy() {
    isRecording = false
    recordingThread?.join(1000)
    
    audioRecord?.apply {
        try {
            if (recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                stop()
            }
        } catch (_: IllegalStateException) { }
        release()
    }
    audioRecord = null
    
    // ✅ Wake lock doğru release ediliyor
    if (wakeLock?.isHeld == true) {
        wakeLock?.release()
    }
    super.onDestroy()
}
```

---

## 🛠️ Uygulama Planı

### Faz 1: Hızlı Kazanımlar (1-2 gün)
1. **Küçük model dene** → `ggml-tiny.bin` test et
2. **Thread sayısını artır** → `n_threads = 4` (whisper-jni.cxx)
3. **Chunk boyutunu optimize et** → 8s → 10-12s arası dene

### Faz 2: Overlapping Chunks (2-3 gün)
1. `AudioRecorderService.kt` - overlap logic ekle
2. Duplicate text post-processing (opsiyonel)
3. Test: kelime kesintisi azaldı mı?

### Faz 3: Parallel Transcription (3-5 gün)
1. Whisper context pool oluştur
2. Thread pool'u 3-4'e çıkar
3. Memory monitoring ekle
4. Crash test (stress test)

### Faz 4: Stability & Polish (2-3 gün)
1. Memory leak testi
2. Uzun kayıt testi (30+ dakika)
3. Termal throttling testi
4. Error handling iyileştirmesi

---

## 📊 Beklenen Performans İyileştirmeleri

| Metrik | Mevcut | Hedef (Faz 1) | Hedef (Faz 3) |
|--------|--------|---------------|---------------|
| Son chunk transcription süresi | 8-15s | 3-5s | 1-2s |
| Kelime kesintisi oranı | %30-40 | %10-15 | %5-10 |
| Crash rate | Bilinmiyor | <1% | <0.1% |
| Memory kullanımı | ~200MB | ~150MB | ~300MB |

---

## ⚠️ Riskler ve Mitigasyon

### Risk 1: Parallel Processing → RAM Patlaması
**Mitigasyon:**
- Max 3 thread pool
- Memory threshold check (85%)
- Düşük RAM cihazlarda fallback to single thread

### Risk 2: Overlap → Duplicate Text
**Mitigasyon:**
- Post-processing: son 2 saniye duplicate kelime temizle
- Veya: UI tarafında merge logic

### Risk 3: Küçük Model → Düşük Doğruluk
**Mitigasyon:**
- A/B test: tiny vs base
- User setting: hız/doğruluk trade-off

---

## 🧪 Test Senaryoları

### Test 1: Kelime Kesintisi
```
1. 30 saniyelik sürekli konuşma kaydet
2. Chunk boundaries'de kelime kesildi mi kontrol et
3. Overlap ile/olmasız karşılaştır
```

### Test 2: Transkripsiyon Hızı
```
1. 5 dakikalık kayıt yap
2. Stop tuşuna bastıktan sonra son transcript ne kadar sürede geldi?
3. Parallel vs serial karşılaştır
```

### Test 3: Crash Stability
```
1. 1 saatlik sürekli kayıt
2. Arka planda diğer uygulamalar aç/kapat
3. App crash etti mi? Memory leak var mı?
```

---

## 📌 Öncelikli Aksiyon Adımları

1. **Şimdi:** Tiny model dene (en kolay, hızlı sonuç)
2. **Bu hafta:** Overlapping chunks implement et
3. **Gelecek hafta:** Parallel transcription test et
4. **Sonrası:** Production stability testing

---

## 💡 Ek Öneriler

### Alternatif 1: Distil-Whisper
- OpenAI Whisper'ın distilled versiyonu
- %50 daha hızlı, %95 doğruluk
- Trade-off: doğruluğu azaltan bazı kenar durumlar

### Alternatif 2: Streaming VAD + Sentence Boundary
- Chunk'ları cümle sınırlarında bitir
- VAD + NLP sentence detector combo
- Daha temiz chunk boundaries

### Alternatif 3: Cloud Hybrid
- İlk 3 chunk → on-device (hızlı preview)
- Geri kalan → cloud (yüksek doğruluk)
- Trade-off: network dependency

---

**Sonraki Adım:** Hangi yaklaşımı tercih ediyorsun? 
1. Tiny model + overlap (hızlı başlangıç)
2. Parallel processing (max hız)
3. İkisi birden (max performans)
