// Draws the app icon to assets/brand/icon_1024.png: a receipt, torn at the
// bottom, with a tick, on the accent. Then: python3 tool/make_icons.py
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/config/palette.dart';

void main() {
  test('icon', () async {
    const s = 1024.0;
    const p = Palette.light;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(const Rect.fromLTWH(0, 0, s, s), Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(s, s), [p.accentGlow, p.accentDeep]));
    // The receipt, slightly turned, with a soft shadow.
    c.save();
    c.translate(512, 520);
    c.rotate(-0.08);
    const w = 470.0, h = 600.0;
    final paper = Path()
      ..moveTo(-w / 2, -h / 2)
      ..lineTo(w / 2, -h / 2)
      ..lineTo(w / 2, h / 2 - 26);
    var x = w / 2;
    var down = true;
    while (x > -w / 2) {
      x -= 33;
      paper.lineTo(x < -w / 2 ? -w / 2 : x, down ? h / 2 : h / 2 - 26);
      down = !down;
    }
    paper.close();
    c.drawPath(paper.shift(const Offset(0, 30)), Paint()
      ..color = const Color(0x55140B3D)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30));
    c.drawPath(paper, Paint()..color = const Color(0xFFFFFEFB));
    final line = Paint()
      ..color = const Color(0xFFE4E1EA)
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    for (final (y, len) in [(-200.0, 300.0), (-130.0, 220.0)]) {
      c.drawLine(Offset(-len / 2, y), Offset(len / 2, y), line);
    }
    // The tick in a ring of the accent.
    c.drawCircle(const Offset(0, 60), 120, Paint()..color = p.accent);
    final tick = Path()
      ..moveTo(-52, 60)
      ..lineTo(-14, 98)
      ..lineTo(58, 22);
    c.drawPath(tick, Paint()
      ..color = p.onAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
    c.restore();
    final img = await rec.endRecording().toImage(s.toInt(), s.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('assets/brand/icon_1024.png')..createSync(recursive: true)..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
