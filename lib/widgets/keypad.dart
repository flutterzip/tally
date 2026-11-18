import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';

/// The amount as typed, large: each new character rises in on its own, and
/// the whole thing shakes when a key is refused ([shake] changes).
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({super.key, required this.typed, this.shake = 0, this.note});

  final String typed;

  /// Bump to shake (a refused key, or more than the balance).
  final int shake;

  /// A line under the amount, such as the balance left.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final shown = typed.isEmpty ? '0' : typed;
    final size = shown.length > 6 ? 52.0 : 64.0;
    final style = text.displaySmall!.copyWith(fontSize: size, color: typed.isEmpty ? p.muted : p.ink, height: 1.1);
    return Semantics(
      label: '\$$shown',
      liveRegion: true,
      excludeSemantics: true,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(shake),
            tween: Tween(begin: shake == 0 ? 1 : 0, end: 1),
            duration: Motion.shake,
            builder: (_, t, child) => Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 14 * (1 - t), 0), child: child),
            child: AnimatedSize(
              duration: Motion.short,
              curve: Motion.settle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: size * 0.12),
                    child: Text('\$', style: style.copyWith(fontSize: size * 0.55, color: p.muted)),
                  ),
                  for (var i = 0; i < shown.length; i++)
                    AnimatedSwitcher(
                      duration: Motion.medium,
                      switchInCurve: Motion.spring,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, 0.45), end: Offset.zero).animate(a),
                          child: ScaleTransition(scale: Tween(begin: 0.6, end: 1.0).animate(a), child: child),
                        ),
                      ),
                      child: Text(shown[i], key: ValueKey('$i${shown[i]}'), style: style),
                    ),
                ],
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            AnimatedSwitcher(duration: Motion.short, child: Text(note!, key: ValueKey(note), style: text.bodySmall)),
          ],
        ],
      ),
    );
  }
}

/// Twelve keys: digits, a point and delete. Each key squeezes and flashes
/// a ring when pressed.
class Keypad extends StatelessWidget {
  const Keypad({super.key, required this.onKey});

  /// '0' to '9', '.', or '<' for delete.
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '<'];
    return Column(
      children: [
        for (var r = 0; r < 4; r++)
          Row(
            children: [
              for (var k = 0; k < 3; k++) Expanded(child: _Key(label: keys[r * 3 + k], onTap: () => onKey(keys[r * 3 + k]))),
            ],
          ),
      ],
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> with SingleTickerProviderStateMixin {
  late final _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  bool _down = false;

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final del = widget.label == '<';
    return Semantics(
      button: true,
      label: del ? 'Delete' : (widget.label == '.' ? 'Point' : widget.label),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.lightImpact();
          _ring.forward(from: 0);
          widget.onTap();
        },
        child: SizedBox(
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _ring,
                builder: (_, _) => _ring.value == 0 || _ring.value == 1
                    ? const SizedBox()
                    : Container(
                        width: 40 + 30 * _ring.value,
                        height: 40 + 30 * _ring.value,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: p.accent.withValues(alpha: 0.18 * (1 - _ring.value))),
                      ),
              ),
              AnimatedScale(
                duration: Motion.quick,
                scale: _down ? 0.82 : 1,
                child: del
                    ? Icon(Icons.backspace_outlined, color: p.inkSoft, size: 26)
                    : Text(widget.label, style: text.headlineSmall!.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drag the knob to the end to confirm. The label shimmers to say "slide
/// me", the track fills behind the knob, and at the end it locks: the knob
/// spins while [busy] and turns into a tick when [done].
class SlideToPay extends StatefulWidget {
  const SlideToPay({super.key, required this.label, required this.onSlid, this.enabled = true, this.busy = false, this.done = false});

  final String label;
  final VoidCallback onSlid;
  final bool enabled, busy, done;

  @override
  State<SlideToPay> createState() => _SlideToPayState();
}

class _SlideToPayState extends State<SlideToPay> with TickerProviderStateMixin {
  static const _h = 68.0, _pad = 6.0;
  late final _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late final _settle = AnimationController(vsync: this, duration: Motion.medium);
  double _x = 0, _from = 0, _max = 1;

  @override
  void initState() {
    super.initState();
    _settle.addListener(() => setState(() => _x = _from * (1 - Motion.spring.transform(_settle.value))));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.loops(context)) {
      if (!_shimmer.isAnimating) _shimmer.repeat();
    } else {
      _shimmer.stop();
    }
  }

  @override
  void didUpdateWidget(SlideToPay old) {
    super.didUpdateWidget(old);
    // Sent back to the start if paying failed.
    if (old.busy && !widget.busy && !widget.done) {
      _from = _x;
      _settle.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _settle.dispose();
    super.dispose();
  }

  bool get _locked => widget.busy || widget.done;

  void _end() {
    if (_x >= _max * 0.86) {
      HapticFeedback.heavyImpact();
      setState(() => _x = _max);
      widget.onSlid();
    } else {
      _from = _x;
      _settle.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      onTap: widget.enabled && !_locked ? widget.onSlid : null,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          _max = box.maxWidth - _h;
          final x = _locked ? _max : _x;
          final fill = (x / _max).clamp(0.0, 1.0);
          return AnimatedOpacity(
            duration: Motion.medium,
            opacity: widget.enabled ? 1 : 0.45,
            child: Container(
              height: _h,
              decoration: BoxDecoration(
                color: p.field,
                borderRadius: BorderRadius.circular(_h / 2),
                border: Border.all(color: p.line),
              ),
              child: Stack(
                children: [
                  // The fill that follows the knob.
                  Container(
                    width: x + _h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_h / 2),
                      gradient: LinearGradient(colors: [p.accentGlow.withValues(alpha: 0.5), p.accent]),
                    ),
                  ),
                  Center(
                    child: Opacity(
                      opacity: (1 - fill * 1.6).clamp(0.0, 1.0),
                      child: AnimatedBuilder(
                        animation: _shimmer,
                        builder: (_, child) => ShaderMask(
                          shaderCallback: (r) {
                            final t = _shimmer.value * 2 - 0.5;
                            return LinearGradient(
                              colors: [p.inkSoft, p.accent, p.inkSoft],
                              stops: [(t - 0.2).clamp(0.0, 1.0), t.clamp(0.0, 1.0), (t + 0.2).clamp(0.0, 1.0)],
                            ).createShader(r);
                          },
                          child: child,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: _h * 0.8),
                          child: Text(widget.label, style: text.labelLarge!.copyWith(color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  if (widget.done)
                    Center(child: Text('Sent', style: text.labelLarge!.copyWith(color: p.onAccent))),
                  AnimatedPositioned(
                    duration: _locked ? Motion.medium : Duration.zero,
                    curve: Motion.spring,
                    left: x + _pad,
                    top: _pad,
                    child: GestureDetector(
                      onHorizontalDragUpdate: !widget.enabled || _locked ? null : (d) => setState(() => _x = (_x + d.delta.dx).clamp(0.0, _max)),
                      onHorizontalDragEnd: !widget.enabled || _locked ? null : (_) => _end(),
                      child: Container(
                        width: _h - _pad * 2,
                        height: _h - _pad * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.card,
                          boxShadow: [BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, 5))],
                        ),
                        child: AnimatedSwitcher(
                          duration: Motion.medium,
                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                          child: widget.done
                              ? Icon(Icons.check_rounded, key: const ValueKey('done'), color: p.accent, size: 28)
                              : widget.busy
                                  ? Padding(
                                      key: const ValueKey('busy'),
                                      padding: const EdgeInsets.all(17),
                                      child: CircularProgressIndicator(strokeWidth: 2.6, color: p.accent),
                                    )
                                  : Icon(Icons.arrow_forward_rounded, key: const ValueKey('go'), color: p.accent, size: 26),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
