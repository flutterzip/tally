import 'package:flutter/material.dart';

import '../config/motion.dart';

/// A number whose digits roll to the new value, each digit on its own
/// wheel (XP, scores, minutes learned).
class RollingNumber extends StatelessWidget {
  const RollingNumber(this.value, {super.key, this.style, this.prefix = '', this.suffix = ''});

  final int value;
  final TextStyle? style;
  final String prefix, suffix;

  @override
  Widget build(BuildContext context) {
    final s = style ?? Theme.of(context).textTheme.titleLarge!;
    final text = '$value';
    return Semantics(
      label: '$prefix$value$suffix',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefix.isNotEmpty) Text(prefix, style: s),
          for (var i = 0; i < text.length; i++)
            _Wheel(key: ValueKey(text.length - i), digit: int.parse(text[i]), style: s),
          if (suffix.isNotEmpty) Text(suffix, style: s),
        ],
      ),
    );
  }
}

/// Any text whose digits roll (a balance like \$12,482.60). Digits are
/// matched from the right, so cents roll as cents when the amount grows a
/// digit; commas, points and symbols simply sit between them.
class RollingText extends StatelessWidget {
  const RollingText(this.text, {super.key, this.style, this.semanticsLabel});

  final String text;
  final TextStyle? style;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final s = style ?? Theme.of(context).textTheme.titleLarge!;
    return Semantics(
      label: semanticsLabel ?? text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < text.length; i++)
            if (RegExp(r'\d').hasMatch(text[i]))
              _Wheel(key: ValueKey('d${text.length - i}'), digit: int.parse(text[i]), style: s)
            else
              Text(text[i], key: ValueKey('c${text.length - i}'), style: s),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({super.key, required this.digit, required this.style});

  final int digit;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final h = (style.fontSize ?? 20) * (style.height ?? 1.3);
    final scale = MediaQuery.textScalerOf(context);
    // Each digit's own width, so a 1 sits close to its neighbours; the
    // wheel narrows and widens as it rolls between digits.
    final widths = [
      for (var n = 0; n <= 9; n++)
        (TextPainter(text: TextSpan(text: '$n', style: style), textDirection: TextDirection.ltr, textScaler: scale)..layout()).width,
    ];
    return TweenAnimationBuilder<double>(
      tween: Tween(end: digit.toDouble()),
      duration: Motion.long,
      curve: Motion.settle,
      builder: (context, v, _) => ClipRect(
        child: SizedBox(
          height: h,
          width: () {
            final a = v.floor().clamp(0, 9), b = v.ceil().clamp(0, 9);
            return widths[a] + (widths[b] - widths[a]) * (v - a);
          }(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var n = 0; n <= 9; n++)
                if ((n - v).abs() < 1.2)
                  Positioned(
                    top: (n - v) * h,
                    left: -20,
                    right: -20,
                    child: Text('$n', style: style, textAlign: TextAlign.center, softWrap: false),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
