import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../data/models.dart';
import 'cards.dart';

/// A person as a round badge of their initials, in one of the card tones.
class Initials extends StatelessWidget {
  const Initials({super.key, required this.contact, this.size = 44});

  final Contact contact;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: CardTones.of(contact.tone)),
      ),
      child: Text(
        contact.initials,
        style: TextStyle(fontFamily: 'Bricolage', fontWeight: FontWeight.w700, fontSize: size * 0.36, color: CardTones.ink(contact.tone)),
      ),
    );
  }
}

/// One movement of money: what it was, when, and how much. Money in is in
/// the accent with a plus; money out is plain.
class TxnRow extends StatelessWidget {
  const TxnRow({super.key, required this.txn, this.contact, this.onTap});

  final Txn txn;
  final Contact? contact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final incoming = txn.cents > 0;
    final sub = [clock(txn.at), txn.note ?? txn.category.label].join(' · ');
    return Semantics(
      label: '${txn.title}, ${money(txn.cents, sign: true)}, $sub',
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Row(
            children: [
              contact != null
                  ? Initials(contact: contact!)
                  : Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: incoming ? p.accentWash : p.field, shape: BoxShape.circle),
                      child: Icon(txn.category.icon, size: 21, color: incoming ? p.accentDeep : p.inkSoft),
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(txn.title, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(sub, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                money(txn.cents, sign: true),
                style: text.titleMedium!.copyWith(color: incoming ? p.accentDeep : p.ink, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A contact to pay: their initials, name under, and a ring that draws
/// round them when chosen.
class ContactBubble extends StatelessWidget {
  const ContactBubble({super.key, required this.contact, required this.selected, required this.onTap});

  final Contact contact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: contact.name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: selected ? 1 : 0),
                      duration: Motion.medium,
                      curve: Motion.settle,
                      builder: (_, t, _) => CustomPaint(size: const Size.square(64), painter: _RingPainter(t, p.accent)),
                    ),
                    AnimatedScale(
                      duration: Motion.medium,
                      curve: Motion.spring,
                      scale: selected ? 1 : 0.9,
                      child: Initials(contact: contact, size: 52),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: Motion.short,
                style: text.labelMedium!.copyWith(color: selected ? p.ink : p.muted),
                child: Text(contact.firstName, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas c, Size s) {
    if (t == 0) return;
    c.drawArc(
      (Offset.zero & s).deflate(2),
      -math.pi / 2,
      math.pi * 2 * t,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.color != color;
}

/// A round action with a label under it (Send, Add card, Cards).
class QuickAction extends StatelessWidget {
  const QuickAction({super.key, required this.icon, required this.label, required this.onTap, this.filled = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? p.accent : p.card,
                border: Border.all(color: filled ? p.accent : p.line),
                boxShadow: [BoxShadow(color: (filled ? p.accent : p.shadow).withValues(alpha: filled ? 0.35 : 0.5), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Icon(icon, color: filled ? p.onAccent : p.ink, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: text.labelMedium),
          ],
        ),
      ),
    );
  }
}

/// Seven days of spending as bars that spring up one after another. Tap a
/// bar to see that day; the chosen one is in the accent.
class SpendBars extends StatelessWidget {
  const SpendBars({super.key, required this.days, required this.selected, required this.onSelect, this.height = 150});

  final List<({DateTime day, int spent})> days;
  final int selected;
  final ValueChanged<int> onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final top = days.fold(1, (m, d) => math.max(m, d.spent));
    return SizedBox(
      height: height + 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                label: '${weekday(days[i].day)}, ${money(days[i].spent)} spent',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(i);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: days[i].spent / top),
                        duration: Duration(milliseconds: 800 + i * 110),
                        curve: Motion.spring,
                        builder: (_, v, _) => AnimatedContainer(
                          duration: Motion.medium,
                          height: (height * v).clamp(6.0, height),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: i == selected ? [p.accentGlow, p.accent] : [p.field, p.line],
                            ),
                            boxShadow: [BoxShadow(color: p.accent.withValues(alpha: i == selected ? 0.3 : 0), blurRadius: 14, offset: const Offset(0, 6))],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(weekday(days[i].day).substring(0, 1), style: text.labelSmall!.copyWith(color: i == selected ? p.ink : p.muted)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Spent against a limit, as a bar that fills and a line of text.
class LimitBar extends StatelessWidget {
  const LimitBar({super.key, required this.spent, required this.limit});

  final int spent, limit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final f = limit == 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Spent this week', style: text.bodySmall)),
            Text('${money(spent)} of ${money(limit, whole: true)}', style: text.labelMedium!.copyWith(color: p.ink)),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (_, box) => Container(
            height: 10,
            decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(5)),
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: f),
              duration: Motion.ring,
              curve: Motion.settle,
              builder: (_, v, _) => Container(
                width: math.max(10, box.maxWidth * v),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [p.accentGlow, p.accent]), borderRadius: BorderRadius.circular(5)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
