import 'dart:io';
import 'dart:typed_data';

class WavWriter {
  const WavWriter();

  Uint8List buildWav({
    required Uint8List pcm16Data,
    int sampleRate = 16000,
    int channels = 1,
  }) {
    const bytesPerSample = 2;
    final byteRate = sampleRate * channels * bytesPerSample;
    final blockAlign = channels * bytesPerSample;
    final totalAudioLen = pcm16Data.length;
    final totalDataLen = totalAudioLen + 36;

    final output = BytesBuilder(copy: false);
    final header = ByteData(44);

    _writeAscii(header, 0, 'RIFF');
    header.setUint32(4, totalDataLen, Endian.little);
    _writeAscii(header, 8, 'WAVE');
    _writeAscii(header, 12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, 16, Endian.little);
    _writeAscii(header, 36, 'data');
    header.setUint32(40, totalAudioLen, Endian.little);

    output
      ..add(header.buffer.asUint8List())
      ..add(pcm16Data);
    return output.toBytes();
  }

  Future<void> writeWavFile({
    required File file,
    required Uint8List pcm16Data,
    int sampleRate = 16000,
    int channels = 1,
  }) async {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(
      buildWav(
        pcm16Data: pcm16Data,
        sampleRate: sampleRate,
        channels: channels,
      ),
      flush: true,
    );
  }

  void _writeAscii(ByteData data, int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}
