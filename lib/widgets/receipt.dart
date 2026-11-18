import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';

/// One line on a receipt: a label on the left, its value on the right.
typedef ReceiptLine = (String label, String value);

/// A receipt printing out of a slot. The paper feeds down out of it, torn
/// edge first, in short steps like a real thermal printer (with a tick of
/// haptics on each), a light on the slot blinks while it works, and then a
/// PAID stamp slams onto it.
class PrintedReceipt extends StatefulWidget {
  const PrintedReceipt({
    super.key,
    required this.title,
    required this.amount,
    required this.lines,
    required this.code,
    this.stamp = 'PAID',
    this.onPrinted,
  });

  final String title, amount, stamp;
  final List<ReceiptLine> lines;

  /// Printed as a barcode and under it.
  final String code;

  /// Called once the stamp has landed.
  final VoidCallback? onPrinted;

  @override
  State<PrintedReceipt> createState() => _PrintedReceiptState();
}

class _PrintedReceiptState extends State<PrintedReceipt> with TickerProviderStateMixin {
  late final _feed = AnimationController(vsync: this, duration: Motion.printing);
  late final _stamp = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  static const _steps = 14;
  int _step = -1;

  /// Printed at once (reduced motion, tests): no feed, no stamp drop.
  bool _instant = false;

  @override
  void initState() {
    super.initState();
    _feed.addListener(_tick);
    _feed.addStatusListener((s) async {
      if (s != AnimationStatus.completed || _instant) return;
      _blink.stop();
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      await _stamp.forward();
      HapticFeedback.heavyImpact();
      widget.onPrinted?.call();
    });
  }

  void _tick() {
    final step = (_feed.value * _steps).floor();
    if (step != _step) {
      _step = step;
      if (step < _steps) HapticFeedback.selectionClick();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_feed.isAnimating || _feed.isCompleted) return;
    if (Motion.reduced(context) || !Motion.ambient) {
      _instant = true;
      _feed.value = 1;
      _stamp.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPrinted?.call();
      });
      return;
    }
    _blink.repeat(reverse: true);
    _feed.forward();
  }

  @override
  void dispose() {
    _feed.dispose();
    _stamp.dispose();
    _blink.dispose();
    super.dispose();
  }

  /// How much paper is out: steps with a short push and a pause, like a
  /// printer head line by line.
  double get _out {
    final v = _feed.value * _steps;
    final whole = v.floor();
    final part = v - whole;
    return ((whole + Curves.easeOutCubic.transform((part * 1.6).clamp(0.0, 1.0))) / _steps).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: '${widget.title}, ${widget.amount}, ${widget.stamp.toLowerCase()}',
      excludeSemantics: true,
      child: Column(
        children: [
          // The printer's slot, with its light.
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: p.ink,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, 8))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _blink,
                  builder: (_, _) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(p.accentGlow, p.accentDeep, _blink.value),
                      boxShadow: [BoxShadow(color: p.accentGlow.withValues(alpha: 1 - _blink.value), blurRadius: 8)],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(height: 5, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(3))),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),
          // The paper, coming out from just under the slot.
          Transform.translate(
            offset: const Offset(0, -12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: AnimatedBuilder(
                animation: Listenable.merge([_feed, _stamp]),
                builder: (_, child) => ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: _out,
                    child: child,
                  ),
                ),
                child: _Paper(title: widget.title, amount: widget.amount, lines: widget.lines, code: widget.code, stamp: _stamp, stampText: widget.stamp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thermal paper is white in any light, so the paper always uses the light
/// palette.
class _Paper extends StatelessWidget {
  const _Paper({required this.title, required this.amount, required this.lines, required this.code, required this.stamp, required this.stampText});

  final String title, amount, code, stampText;
  final List<ReceiptLine> lines;

  /// The stamp lands in its own blank band, clear of the text and barcode.
  final Animation<double> stamp;

  @override
  Widget build(BuildContext context) {
    const p = Palette.light;
    final text = Theme.of(context).textTheme;
    final label = text.bodySmall!.copyWith(color: p.muted);
    final value = text.bodyMedium!.copyWith(color: p.ink, fontWeight: FontWeight.w600);
    return ClipPath(
      clipper: _TornEdge(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 34),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.field, p.card, p.card]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('tally', textAlign: TextAlign.center, style: text.titleLarge!.copyWith(color: p.ink, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: label),
            const SizedBox(height: 18),
            Text(amount, textAlign: TextAlign.center, style: text.displaySmall!.copyWith(color: p.ink, fontSize: 40)),
            const SizedBox(height: 18),
            const _Dashes(color: Color(0xFFD5D1DD)),
            const SizedBox(height: 14),
            for (final (l, v) in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Text(l, style: label),
                    const SizedBox(width: 12),
                    Expanded(child: Text(v, textAlign: TextAlign.right, style: value, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            const _Dashes(color: Color(0xFFD5D1DD)),
            SizedBox(
              height: 92,
              child: Center(
                child: AnimatedBuilder(
                  animation: stamp,
                  builder: (_, _) => _Stamp(t: stamp.value, text: stampText, color: p.accent),
                ),
              ),
            ),
            SizedBox(height: 46, child: CustomPaint(painter: _BarcodePainter(code, p.ink))),
            const SizedBox(height: 6),
            Text(code, textAlign: TextAlign.center, style: label.copyWith(letterSpacing: 3)),
            const SizedBox(height: 12),
            Text('Thank you', textAlign: TextAlign.center, style: label),
          ],
        ),
      ),
    );
  }
}

class _Dashes extends StatelessWidget {
  const _Dashes({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = color;
    return LayoutBuilder(
      builder: (_, box) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (var i = 0; i < (box.maxWidth / 9).floor(); i++) Container(width: 5, height: 1.6, color: c)],
      ),
    );
  }
}

/// The bottom of the paper, torn in a zigzag.
class _TornEdge extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    const tooth = 10.0, depth = 8.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width, s.height - depth);
    var x = s.width;
    var down = true;
    while (x > 0) {
      x = math.max(0, x - tooth / 2);
      path.lineTo(x, down ? s.height : s.height - depth);
      down = !down;
    }
    return path..close();
  }

  @override
  bool shouldReclip(_TornEdge old) => false;
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.code, this.ink);

  final String code;
  final Color ink;

  @override
  void paint(Canvas c, Size s) {
    // Bar widths from the code's characters, so each receipt is its own.
    final widths = <double>[];
    for (final u in code.codeUnits) {
      widths.addAll([1 + u % 3, 1 + (u >> 2) % 2, 2 + (u >> 1) % 3, 1 + (u >> 3) % 2]);
    }
    final total = widths.fold(0.0, (a, b) => a + b);
    final unit = s.width * 0.8 / total;
    var x = s.width * 0.1;
    final paint = Paint()..color = ink;
    for (var i = 0; i < widths.length; i++) {
      if (i.isEven) c.drawRect(Rect.fromLTWH(x, 0, widths[i] * unit, s.height), paint);
      x += widths[i] * unit;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.code != code || old.ink != ink;
}

/// A rubber stamp: it drops from above at [t] 0, slams down past full size
/// and settles, slightly crooked, in ink with worn edges.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.t, required this.text, required this.color});

  final double t;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (t == 0) return const SizedBox();
    final scale = 2.6 - 1.6 * Curves.easeOutBack.transform(t);
    return Opacity(
      opacity: (t * 2.5).clamp(0.0, 1.0),
      child: Transform.rotate(
        angle: -0.22,
        child: Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.85), width: 3),
            ),
            child: ShaderMask(
              shaderCallback: (r) => RadialGradient(
                center: const Alignment(0.6, -0.4),
                radius: 1.4,
                colors: [color.withValues(alpha: 0.7), color, color.withValues(alpha: 0.8)],
              ).createShader(r),
              child: Text(text, style: const TextStyle(fontFamily: 'Bricolage', fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 3, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
