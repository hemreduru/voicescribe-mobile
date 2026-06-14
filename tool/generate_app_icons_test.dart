// ignore_for_file: avoid_print
//
// Renders the PNG masters that flutter_launcher_icons consumes, using only the
// Flutter SDK (dart:ui under flutter_test) — no system rasterizer required.
// The geometry mirrors the design source SVGs in brand/app_icon/ and
// brand/logo/icon-mark-color.svg.
//
// Run explicitly (it is NOT auto-discovered by `flutter test`, which only scans
// test/):
//   flutter test tool/generate_app_icons_test.dart
//
// Outputs to brand/app_icon/generated/:
//   ic_bg_1024.png   adaptive background (Signal Teal gradient)
//   ic_fg_1024.png   adaptive foreground (waveform, transparent, safe-zone)
//   ic_app_1024.png  iOS / master (gradient tile + waveform)
//   mark_24.png      logo mark at 24px (legibility check)
//   mark_96.png / mark_512.png  logo mark previews

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _glow = Color(0xFF2DD4CF);
const _primary = Color(0xFF0B7884);

// Waveform bars in a 1024 canvas: [x, y, w, h]. Solid white for punch at
// launcher sizes.
const _fgBars = <List<double>>[
  [228, 380, 76, 264],
  [351, 284, 76, 456],
  [474, 218, 76, 588],
  [597, 304, 76, 416],
  [720, 360, 76, 304],
];

// Logo-mark bars in a 96 canvas (tile spans 12..84): [x, y, w, h, opacity].
const _markBars = <List<double>>[
  [16, 36, 8, 24, 0.85],
  [30, 26, 8, 44, 0.92],
  [44, 18, 8, 60, 1],
  [58, 27, 8, 42, 0.92],
  [72, 34, 8, 28, 0.85],
];

Shader _tealShader(Rect r) => const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_glow, _primary],
).createShader(r);

void _paintGradientSquare(Canvas c, double size) {
  final r = Rect.fromLTWH(0, 0, size, size);
  c.drawRect(r, Paint()..shader = _tealShader(r));
}

void _paintBars(
  Canvas c,
  List<List<double>> bars,
  double srcSize,
  double dstSize,
  double radius,
) {
  final s = dstSize / srcSize;
  for (final b in bars) {
    final opacity = b.length > 4 ? b[4] : 1.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(b[0] * s, b[1] * s, b[2] * s, b[3] * s),
      Radius.circular(radius * s),
    );
    c.drawRRect(rrect, Paint()..color = Colors.white.withValues(alpha: opacity));
  }
}

void _paintMark(Canvas c, double size) {
  final s = size / 96;
  final r = Rect.fromLTWH(12 * s, 12 * s, 72 * s, 72 * s);
  c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(22 * s)),
    Paint()..shader = _tealShader(r),
  );
  _paintBars(c, _markBars, 96, size, 4);
}

Future<void> _writePng(String path, int size, void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  print('wrote $path (${size}x$size)');
}

void main() {
  testWidgets('generate app icon + mark PNGs', (tester) async {
    await tester.runAsync(() async {
      const out = 'brand/app_icon/generated';
      Directory(out).createSync(recursive: true);

      await _writePng('$out/ic_bg_1024.png', 1024, (c) {
        _paintGradientSquare(c, 1024);
      });
      await _writePng('$out/ic_fg_1024.png', 1024, (c) {
        // Enlarge ~1.3x around centre so that, after flutter_launcher_icons'
        // 16% adaptive inset, the waveform matches the iOS master's visual
        // weight while staying inside the adaptive safe zone.
        c
          ..translate(512, 512)
          ..scale(1.3)
          ..translate(-512, -512);
        _paintBars(c, _fgBars, 1024, 1024, 38);
      });
      await _writePng('$out/ic_app_1024.png', 1024, (c) {
        _paintGradientSquare(c, 1024);
        _paintBars(c, _fgBars, 1024, 1024, 38);
      });

      // Composite preview simulating Android's adaptive render (background +
      // foreground at the 16% inset, after the 1.3x foreground enlargement).
      await _writePng('$out/preview_android.png', 512, (c) {
        _paintGradientSquare(c, 512);
        c
          ..save()
          ..translate(256, 256)
          ..scale(0.68 * 1.3)
          ..translate(-256, -256);
        _paintBars(c, _fgBars, 1024, 512, 38);
        c.restore();
      });

      await _writePng('$out/mark_24.png', 24, (c) => _paintMark(c, 24));
      await _writePng('$out/mark_96.png', 96, (c) => _paintMark(c, 96));
      await _writePng('$out/mark_512.png', 512, (c) => _paintMark(c, 512));
    });
  });
}
