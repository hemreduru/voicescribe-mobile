import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/l10n/app_localizations.dart';

const _kilobyte = 1024;
const _megabyte = _kilobyte * 1024;
const _gigabyte = _megabyte * 1024;

enum _ByteUnit { kb, mb, gb }

String formatModelDownloadBytes(int bytes) {
  if (bytes >= _gigabyte) {
    return _formatBytes(bytes, unit: _ByteUnit.gb);
  }
  if (bytes >= _megabyte) {
    return _formatBytes(bytes, unit: _ByteUnit.mb);
  }
  return _formatBytes(bytes, unit: _ByteUnit.kb);
}

String formatModelDownloadProgress(
  AppLocalizations l10n,
  ModelDownloadProgress progress,
) {
  final percent = progress.percent;
  final downloaded = formatModelDownloadBytes(progress.bytesDownloaded);
  final totalBytes = progress.totalBytes;
  if (percent == null || totalBytes == null) {
    return '${l10n.modelDownloading} $downloaded';
  }
  final unit = _preferredUnit(totalBytes);
  final total = _formatBytes(totalBytes, unit: unit);
  final downloadedValue = _formatBytes(progress.bytesDownloaded, unit: unit);
  return '${l10n.modelDownloadingPercent(percent.floor())} '
      '($downloadedValue / $total)';
}

_ByteUnit _preferredUnit(int bytes) {
  if (bytes >= _gigabyte) {
    return _ByteUnit.gb;
  }
  if (bytes >= _megabyte) {
    return _ByteUnit.mb;
  }
  return _ByteUnit.kb;
}

String _formatBytes(int bytes, {required _ByteUnit unit}) {
  switch (unit) {
    case _ByteUnit.gb:
      return '${_formatDecimal(bytes / _gigabyte)} GB';
    case _ByteUnit.mb:
      return '${_formatDecimal(bytes / _megabyte)} MB';
    case _ByteUnit.kb:
      return '${(bytes / _kilobyte).round()} KB';
  }
}

String _formatDecimal(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
