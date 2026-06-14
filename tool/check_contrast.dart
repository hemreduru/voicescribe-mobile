// ignore_for_file: avoid_print
//
// Reproducible WCAG 2.1 contrast verification for the Signal Teal palette.
// Run: `dart run tool/check_contrast.dart`
//
// Confirms every text/background role pair in app_theme.dart meets WCAG AA
// (4.5:1 normal text, 3:1 large text / graphics). The printed ratios are the
// source of the figures listed in brand/BRAND_GUIDELINES.html.

import 'dart:math' as math;

double _channel(int c) {
  final s = c / 255.0;
  return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(int rgb) {
  final r = (rgb >> 16) & 0xFF;
  final g = (rgb >> 8) & 0xFF;
  final b = rgb & 0xFF;
  return 0.2126 * _channel(r) + 0.7152 * _channel(g) + 0.0722 * _channel(b);
}

double contrast(int fg, int bg) {
  final l1 = _luminance(fg);
  final l2 = _luminance(bg);
  final hi = math.max(l1, l2);
  final lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

class Pair {
  const Pair(this.label, this.fg, this.bg, this.min);
  final String label;
  final int fg;
  final int bg;
  final double min;
}

void main() {
  const pairs = <Pair>[
    // ---- Light ----
    Pair('L  onPrimary / primary (button)', 0xFFFFFF, 0x0B7884, 4.5),
    Pair('L  primary / primaryContainer (nav/tab label)', 0x0B7884, 0xD9F7F4, 4.5),
    Pair('L  onPrimaryContainer / primaryContainer', 0x053238, 0xD9F7F4, 4.5),
    Pair('L  onSecondary / secondary (button)', 0xFFFFFF, 0x0E6E84, 4.5),
    Pair('L  onSecondaryContainer / secondaryContainer', 0x082C36, 0xD2ECF1, 4.5),
    Pair('L  onSurface / surface', 0x1E293B, 0xFFFFFF, 4.5),
    Pair('L  onSurfaceVariant / surface', 0x475569, 0xFFFFFF, 4.5),
    Pair('L  success(positive) / surface [graphic 3:1]', 0x15803D, 0xFFFFFF, 3),
    Pair('L  glow top / white (idle core icon) [graphic 3:1]', 0xFFFFFF, 0x119A91, 3),
    // ---- Dark ----
    Pair('D  onPrimary / primary (button)', 0x063038, 0x5FE3DC, 4.5),
    Pair('D  primary / surface (text/icon)', 0x5FE3DC, 0x0D1118, 4.5),
    Pair('D  primary / primaryContainer (nav/tab label)', 0x5FE3DC, 0x0E565C, 4.5),
    Pair('D  onPrimaryContainer / primaryContainer', 0xCFF5F1, 0x0E565C, 4.5),
    Pair('D  onSecondary / secondary (button)', 0x04303D, 0x7FDCEA, 4.5),
    Pair('D  onSecondaryContainer / secondaryContainer', 0xD2ECF1, 0x154A57, 4.5),
    Pair('D  onSurface / surface', 0xE7EDF8, 0x0D1118, 4.5),
  ];

  var allPass = true;
  for (final p in pairs) {
    final ratio = contrast(p.fg, p.bg);
    final pass = ratio >= p.min;
    allPass = allPass && pass;
    final tag = pass ? 'PASS' : 'FAIL';
    print('[$tag] ${ratio.toStringAsFixed(2)}:1  (min ${p.min})  ${p.label}');
  }
  print('');
  print(allPass ? 'ALL PASS' : 'SOME FAILED — adjust palette');
}
