import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../data/models.dart';

/// The width of a bank card over its height.
const cardAspect = 1.586;

/// Card colours: four steps of the one accent. Cards are the product, so
/// they look the same in light and dark.
abstract final class CardTones {
  static const _p = Palette.light;

  static List<Color> of(int tone) => switch (tone % 4) {
        0 => [_p.accentDeep, _p.accent],
        1 => [_p.accent, _p.accentGlow],
        2 => [const Color(0xFF15122A), _p.accentDeep],
        _ => [_p.accentWash, _p.accentGlow],
      };

  /// Type on the card: dark on the pale tone, light on the rest.
  static Color ink(int tone) => tone % 4 == 3 ? const Color(0xFF1C1640) : const Color(0xFFF7F5FF);

  static const count = 4;
}

/// The front of a card: a gradient in one of the [CardTones] with fine
/// guilloche lines, a drawn chip and contactless mark, the number, name
/// and expiry. A sheen of light sweeps across it now and then.
///
/// [number] is shown as typed (for the add card preview, missing digits are
/// dots) unless [masked], when only the last four show.
class CardFace extends StatefulWidget {
  const CardFace({
    super.key,
    required this.tone,
    required this.name,
    required this.number,
    required this.expiry,
    this.kind = 'Debit',
    this.holder = '',
    this.masked = true,
    this.frozen = false,
    this.width = 340,
  });

  CardFace.of(PayCard card, {Key? key, String holder = '', bool masked = true, double width = 340})
      : this(
          key: key,
          tone: card.tone,
          name: card.name,
          number: card.number,
          expiry: card.expiry,
          kind: card.kind,
          holder: holder,
          masked: masked,
          frozen: card.frozen,
          width: width,
        );

  final int tone;
  final String name, number, expiry, kind, holder;
  final bool masked, frozen;
  final double width;

  @override
  State<CardFace> createState() => _CardFaceState();
}

class _CardFaceState extends State<CardFace> with SingleTickerProviderStateMixin {
  late final _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.loops(context)) {
      if (!_shine.isAnimating) _shine.repeat();
    } else {
      _shine.stop();
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w / cardAspect;
    final ink = CardTones.ink(widget.tone);
    final mono = TextStyle(fontFamily: 'Bricolage', color: ink, fontWeight: FontWeight.w600, letterSpacing: 1.6, fontSize: w * 0.062);
    final small = TextStyle(fontFamily: 'Bricolage', color: ink.withValues(alpha: 0.72), fontSize: w * 0.032, fontWeight: FontWeight.w600, letterSpacing: 0.6);
    final strong = small.copyWith(color: ink, fontSize: w * 0.042, letterSpacing: 0.2);

    return Semantics(
      label: '${widget.name} card ending ${_last4(widget.number)}${widget.frozen ? ', frozen' : ''}',
      excludeSemantics: true,
      child: SizedBox(
        width: w,
        height: h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w * 0.06),
            boxShadow: [BoxShadow(color: CardTones.of(widget.tone).first.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 16))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.06),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: Motion.long,
                    curve: Motion.settle,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: CardTones.of(widget.tone)),
                    ),
                  ),
                ),
                Positioned.fill(child: CustomPaint(painter: _GuillochePainter(ink))),
                Padding(
                  padding: EdgeInsets.all(w * 0.065),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(widget.name, style: strong, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text('tally', style: strong.copyWith(fontSize: w * 0.064, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        ],
                      ),
                      SizedBox(height: h * 0.1),
                      Row(
                        children: [
                          CustomPaint(size: Size(w * 0.13, w * 0.1), painter: _ChipPainter()),
                          SizedBox(width: w * 0.04),
                          CustomPaint(size: Size(w * 0.06, w * 0.08), painter: _WavesPainter(ink)),
                        ],
                      ),
                      const Spacer(),
                      _Number(text: _shown(widget.number, widget.masked), style: mono),
                      SizedBox(height: h * 0.05),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              widget.holder.isEmpty ? widget.kind.toUpperCase() : widget.holder.toUpperCase(),
                              style: small.copyWith(color: ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('VALID ', style: small.copyWith(fontSize: w * 0.022)),
                          Text(widget.expiry.isEmpty ? 'MM/YY' : widget.expiry, style: small.copyWith(color: ink)),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _shine,
                      builder: (_, _) => CustomPaint(painter: _SheenPainter(_shine.value)),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: widget.frozen ? 1 : 0),
                      duration: Motion.frost,
                      curve: Curves.easeInOutCubic,
                      builder: (_, t, _) => t == 0 ? const SizedBox() : Frost(progress: t, seed: widget.name.length + widget.tone),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _last4(String number) {
  final d = number.replaceAll(' ', '');
  return d.length < 4 ? d : d.substring(d.length - 4);
}

/// The number as it should show: masked to the last four, or as typed with
/// dots for the digits still to come.
String _shown(String number, bool masked) {
  final d = number.replaceAll(' ', '');
  if (masked && d.length >= 4) return '••••  ••••  ••••  ${d.substring(d.length - 4)}';
  final b = StringBuffer();
  for (var i = 0; i < 16; i++) {
    if (i > 0 && i % 4 == 0) b.write('  ');
    b.write(i < d.length ? d[i] : '•');
  }
  return b.toString();
}

/// Each character on its own slot, so a new digit drops in where a dot was.
class _Number extends StatelessWidget {
  const _Number({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < text.length; i++)
            AnimatedSwitcher(
              duration: Motion.short,
              switchInCurve: Motion.spring,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(position: Tween(begin: const Offset(0, -0.6), end: Offset.zero).animate(a), child: child),
              ),
              child: Text(text[i], key: ValueKey('$i${text[i]}'), style: style),
            ),
        ],
      ),
    );
  }
}

class _GuillochePainter extends CustomPainter {
  _GuillochePainter(this.ink);

  final Color ink;

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = ink.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final ctr = Offset(s.width * 1.05, s.height * 1.1);
    for (var i = 0; i < 26; i++) {
      final r = s.width * (0.25 + i * 0.035);
      final path = Path();
      for (var a = 0.0; a <= math.pi * 2; a += 0.02) {
        final wobble = 1 + 0.03 * math.sin(a * 9 + i * 0.5);
        final p = ctr + Offset(math.cos(a), math.sin(a)) * r * wobble;
        a == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      c.drawPath(path, paint);
    }
    // A soft glow in the top left.
    c.drawCircle(Offset(s.width * 0.1, 0), s.width * 0.6, Paint()
      ..shader = ui.Gradient.radial(Offset(s.width * 0.1, 0), s.width * 0.6, [const Color(0x2EFFFFFF), const Color(0x00FFFFFF)]));
  }

  @override
  bool shouldRepaint(_GuillochePainter old) => old.ink != ink;
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.height * 0.22));
    c.drawRRect(r, Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(s.width, s.height), const [Color(0xFFF3DFA2), Color(0xFFC9A55A), Color(0xFFEBD08D)], const [0, 0.55, 1]));
    final line = Paint()
      ..color = const Color(0x66855F1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    c.drawLine(Offset(0, s.height * 0.35), Offset(s.width * 0.32, s.height * 0.35), line);
    c.drawLine(Offset(0, s.height * 0.65), Offset(s.width * 0.32, s.height * 0.65), line);
    c.drawLine(Offset(s.width * 0.68, s.height * 0.35), Offset(s.width, s.height * 0.35), line);
    c.drawLine(Offset(s.width * 0.68, s.height * 0.65), Offset(s.width, s.height * 0.65), line);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(s.width * 0.32, s.height * 0.2, s.width * 0.68, s.height * 0.8), const Radius.circular(3)), line);
  }

  @override
  bool shouldRepaint(_ChipPainter old) => false;
}

class _WavesPainter extends CustomPainter {
  _WavesPainter(this.ink);

  final Color ink;

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = ink.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.11
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final r = s.height * (0.18 + i * 0.16);
      c.drawArc(Rect.fromCircle(center: Offset(0, s.height / 2), radius: r), -0.75, 1.5, false, paint);
    }
  }

  @override
  bool shouldRepaint(_WavesPainter old) => old.ink != ink;
}

class _SheenPainter extends CustomPainter {
  _SheenPainter(this.t);

  final double t;

  @override
  void paint(Canvas c, Size s) {
    // Sweeps across in the first quarter of the loop, then rests.
    final p = (t * 4).clamp(0.0, 1.0);
    if (p == 0 || p == 1) return;
    final x = -s.width * 0.6 + p * s.width * 2.2;
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x, 0),
          Offset(x + s.width * 0.45, s.height),
          const [Color(0x00FFFFFF), Color(0x38FFFFFF), Color(0x00FFFFFF)],
          const [0, 0.5, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.t != t;
}

/// Frost over a frozen card: ice crystals grow in from the edges and
/// branch as [progress] goes 0 to 1, under a pale veil, then a snowflake
/// and "Frozen" settle in the middle. Running it backwards melts it.
class Frost extends StatelessWidget {
  const Frost({super.key, required this.progress, this.seed = 1});

  final double progress;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final t = progress;
    return Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 6 * t, sigmaY: 6 * t),
          child: const SizedBox.expand(),
        ),
        CustomPaint(painter: _FrostPainter(t, seed)),
        Center(
          child: Opacity(
            opacity: ((t - 0.55) / 0.45).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.7 + 0.3 * Curves.easeOutBack.transform(((t - 0.55) / 0.45).clamp(0.0, 1.0)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ac_unit_rounded, color: Color(0xFF2B2366), size: 26),
                  const SizedBox(width: 8),
                  Text('Frozen', style: const TextStyle(fontFamily: 'Bricolage', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2B2366))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FrostPainter extends CustomPainter {
  _FrostPainter(this.t, this.seed);

  final double t;
  final int seed;

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = Color.fromRGBO(236, 240, 255, 0.55 * t));
    final rng = math.Random(seed);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeCap = StrokeCap.round;
    // Crystals start along all four edges and grow inwards.
    for (var i = 0; i < 22; i++) {
      final edge = i % 4;
      final along = rng.nextDouble();
      final start = switch (edge) {
        0 => Offset(along * s.width, 0),
        1 => Offset(s.width, along * s.height),
        2 => Offset(along * s.width, s.height),
        _ => Offset(0, along * s.height),
      };
      final inward = switch (edge) { 0 => math.pi / 2, 1 => math.pi, 2 => -math.pi / 2, _ => 0.0 } + (rng.nextDouble() - 0.5) * 0.9;
      final len = s.shortestSide * (0.25 + rng.nextDouble() * 0.3);
      final delay = rng.nextDouble() * 0.35;
      final grow = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      _branch(c, paint, start, inward, len * Curves.easeOutCubic.transform(grow), 2.2, 3, rng);
    }
  }

  void _branch(Canvas c, Paint paint, Offset from, double angle, double len, double width, int depth, math.Random rng) {
    if (len < 2) return;
    final to = from + Offset(math.cos(angle), math.sin(angle)) * len;
    c.drawLine(from, to, paint..strokeWidth = width);
    if (depth == 0) return;
    for (var k = 1; k <= 3; k++) {
      final at = Offset.lerp(from, to, k / 4)!;
      final side = rng.nextBool() ? 1 : -1;
      _branch(c, paint, at, angle + side * (0.7 + rng.nextDouble() * 0.3), len * 0.35, width * 0.6, depth - 1, rng);
    }
  }

  @override
  bool shouldRepaint(_FrostPainter old) => old.t != t;
}

/// The back of a card: the magnetic strip and the signature panel with
/// the security code.
class CardBack extends StatelessWidget {
  const CardBack({super.key, required this.tone, required this.cvv, this.width = 340, this.highlight = false});

  final int tone;
  final String cvv;
  final double width;

  /// Rings the security code while it is being typed.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final w = width, h = w / cardAspect;
    final ink = CardTones.ink(tone);
    return SizedBox(
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(w * 0.06),
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: CardTones.of(tone)),
          boxShadow: [BoxShadow(color: CardTones.of(tone).first.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 16))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: h * 0.12),
            Container(height: h * 0.2, color: const Color(0xFF0E0B1E)),
            SizedBox(height: h * 0.1),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.065),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: h * 0.17,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(colors: [Color(0xFFF2F0F7), Color(0xFFDAD6E6)]),
                      ),
                      child: CustomPaint(painter: _SignaturePainter()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: Motion.medium,
                    width: w * 0.2,
                    height: h * 0.17,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: highlight ? const Color(0xFFFFC94D) : Colors.transparent, width: 2.5),
                      boxShadow: [BoxShadow(color: const Color(0xFFFFC94D).withValues(alpha: highlight ? 0.6 : 0), blurRadius: 14)],
                    ),
                    child: Text(
                      cvv.isEmpty ? '•••' : cvv.padRight(3, '•'),
                      style: TextStyle(fontFamily: 'Bricolage', fontWeight: FontWeight.w700, fontSize: w * 0.05, color: const Color(0xFF1C1640), letterSpacing: 2),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(w * 0.065, 0, w * 0.065, h * 0.08),
              child: Text(
                'This card is a demo. It cannot be used to pay.',
                style: TextStyle(fontFamily: 'Bricolage', fontSize: w * 0.028, color: ink.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var x = -s.height; x < s.width; x += 6) {
      c.drawLine(Offset(x, s.height), Offset(x + s.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => false;
}

/// A card that turns over: [flipped] shows the back. It turns on its
/// vertical axis with perspective, lifting slightly at the midpoint.
class FlipCard extends StatelessWidget {
  const FlipCard({super.key, required this.front, required this.back, required this.flipped});

  final Widget front, back;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: flipped ? 1 : 0),
      duration: Motion.flip,
      curve: Curves.easeInOutCubic,
      builder: (_, t, _) {
        final angle = t * math.pi;
        final lift = 1 + 0.06 * math.sin(t * math.pi);
        final showBack = t > 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle)
            ..scaleByDouble(lift, lift, 1, 1),
          child: showBack ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: back) : front,
        );
      },
    );
  }
}

/// The wallet: cards stacked with the chosen one in front and the rest
/// peeking out above it, smaller and dimmer the further back they are.
/// Tap a card behind to bring it forward, or flick the front card sideways
/// to send it to the back.
class CardStack extends StatefulWidget {
  const CardStack({super.key, required this.cards, required this.front, required this.onFront, this.holder = '', this.width = 340, this.reveal = false});

  final List<PayCard> cards;
  final String front;
  final ValueChanged<String> onFront;
  final String holder;
  final double width;

  /// Shows the front card's whole number, each digit dropping in where a
  /// dot was.
  final bool reveal;

  @override
  State<CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> with SingleTickerProviderStateMixin {
  static const _peek = 22.0;
  double _drag = 0;
  late final AnimationController _back;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _back = AnimationController(vsync: this, duration: Motion.medium)
      ..addListener(() => setState(() => _drag = _from * (1 - Motion.spring.transform(_back.value))));
  }

  List<PayCard> get _ordered {
    final front = widget.cards.firstWhere((c) => c.id == widget.front, orElse: () => widget.cards.first);
    final i = widget.cards.indexOf(front);
    // Behind the front card: the ones after it, wrapping round.
    return [for (var k = 0; k < widget.cards.length; k++) widget.cards[(i + k) % widget.cards.length]];
  }

  void _end(DragEndDetails d) {
    final cards = _ordered;
    if ((_drag.abs() > widget.width * 0.3 || d.primaryVelocity!.abs() > 900) && cards.length > 1) {
      HapticFeedback.mediumImpact();
      widget.onFront(cards[1].id);
      setState(() => _drag = 0);
    } else {
      _from = _drag;
      _back.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = _ordered;
    final n = cards.length;
    final h = widget.width / cardAspect;
    final shown = math.min(n, 4);
    return SizedBox(
      width: widget.width,
      height: h + (shown - 1) * _peek,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Furthest back first, so the front card paints last.
          for (var depth = shown - 1; depth >= 0; depth--)
            AnimatedPositioned(
              key: ValueKey(cards[depth].id),
              duration: Motion.long,
              curve: Motion.spring,
              left: 0,
              right: 0,
              top: (shown - 1 - depth) * _peek,
              child: _layer(cards[depth], depth),
            ),
        ],
      ),
    );
  }

  Widget _layer(PayCard card, int depth) {
    // The same widgets at every depth, so a card animates (rather than
    // jumps) as it moves forward or back.
    final front = depth == 0;
    final drag = front ? _drag : 0.0;
    return GestureDetector(
      onTap: front
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onFront(card.id);
            },
      onHorizontalDragUpdate: front ? (d) => setState(() => _drag += d.delta.dx) : null,
      onHorizontalDragEnd: front ? _end : null,
      child: Transform.translate(
        offset: Offset(drag, 0),
        child: Transform.rotate(
          angle: drag / widget.width * 0.25,
          child: AnimatedScale(
            duration: Motion.long,
            curve: Motion.spring,
            scale: 1 - depth * 0.06,
            alignment: Alignment.topCenter,
            child: AnimatedOpacity(
              duration: Motion.medium,
              opacity: 1 - depth * 0.18,
              child: CardFace.of(card, holder: widget.holder, width: widget.width, masked: !(front && widget.reveal)),
            ),
          ),
        ),
      ),
    );
  }
}
