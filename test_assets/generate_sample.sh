#!/usr/bin/env bash
# Regenerates test_assets/turkish16k.wav — the fixture used by
# integration_test/whisper_turkish_test.dart to validate on-device Whisper
# transcription without relying on the microphone.
#
# Why this exists: the Android emulator on this machine does NOT forward host
# microphone audio into the guest (the guest audio HAL only ever sees silence,
# even with `-allow-host-audio` and an active PipeWire capture stream). So the
# only reliable way to exercise the real transcription pipeline is to feed a
# known WAV directly to WhisperTranscriptionService.transcribeChunk.
#
# Requirements: curl, gstreamer (gst-launch-1.0). Network access to Google TTS.
set -euo pipefail
cd "$(dirname "$0")"

SENTENCE="Merhaba, bugün hava çok güzel ve ben sesli not uygulamasını test ediyorum."
echo "Ground truth: $SENTENCE"

curl -s -A "Mozilla/5.0" --get "https://translate.google.com/translate_tts" \
  --data-urlencode "q=$SENTENCE" -d "ie=UTF-8&tl=tr&client=tw-ob" -o /tmp/tts_tr.mp3

# Whisper expects 16 kHz mono 16-bit PCM (transcribeChunk is called with
# convert:false), so resample/downmix here.
gst-launch-1.0 -q filesrc location=/tmp/tts_tr.mp3 ! decodebin ! audioconvert \
  ! audioresample ! "audio/x-raw,rate=16000,channels=1,format=S16LE" \
  ! wavenc ! filesink location=turkish16k.wav

echo "Wrote $(pwd)/turkish16k.wav"
