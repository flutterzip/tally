import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';

/// A titled group of options with the current choice at the right.
class OptionSection extends StatelessWidget {
  const OptionSection({
    super.key,
    required this.title,
    required this.child,
    this.value,
  });

  final String title;
  final String? value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: text.titleMedium, maxLines: 1)),
            if (value != null)
              AnimatedSwitcher(
                duration: Motion.short,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(a),
                    child: c,
                  ),
                ),
                child: Text(
                  value!,
                  key: ValueKey(value),
                  style: text.bodySmall,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// A row of segments with an accent pill that slides to the chosen one.
/// [labels] and [icons] line up with the segments.
class Segments<T> extends StatelessWidget {
  const Segments({
    super.key,
    required this.values,
    required this.value,
    required this.onChanged,
    required this.label,
    this.icon,
    this.height = 52,
  });

  final List<T> values;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T) label;
  final Widget Function(T, bool selected)? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final index = values.indexOf(value);
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: BorderRadius.circular(Tokens.fieldRadius),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.medium,
                curve: Motion.spring,
                left: index * w,
                width: w,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(Tokens.fieldRadius - 4),
                    boxShadow: [
                      BoxShadow(
                        color: p.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    for (final v in values)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: v == value,
                          label: label(v),
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (v == value) return;
                              HapticFeedback.selectionClick();
                              onChanged(v);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (icon != null) ...[
                                  icon!(v, v == value),
                                  const SizedBox(width: 8),
                                ],
                                // Shrinks rather than overflow at large text
                                // sizes or with a long label.
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: AnimatedDefaultTextStyle(
                                      duration: Motion.short,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium!
                                          .copyWith(
                                            color: v == value ? p.ink : p.muted,
                                            fontWeight: v == value
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                      child: Text(label(v), maxLines: 1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Wrapping choice chips with a fill that pours into the chosen one.
class Choices<T> extends StatelessWidget {
  const Choices({
    super.key,
    required this.values,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final List<T> values;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T) label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final v in values)
          Semantics(
            button: true,
            selected: v == value,
            label: label(v),
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
              child: AnimatedContainer(
                duration: Motion.medium,
                curve: Motion.settle,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: v == value ? p.accent : p.card,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: v == value ? p.accent : p.line),
                ),
                child: Text(
                  label(v),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: v == value ? p.onAccent : p.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// − n +, the number rolling up or down.
class CountStepper extends StatelessWidget {
  const CountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 3,
    this.label = 'shots',
  });

  final int value, min, max;
  final ValueChanged<int> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget button(IconData icon, String name, int next, bool enabled) =>
        Semantics(
          button: true,
          enabled: enabled,
          label: name,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(next);
                  }
                : null,
            child: AnimatedContainer(
              duration: Motion.short,
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? p.card : p.field,
                border: Border.all(color: enabled ? p.line : p.field),
              ),
              child: Icon(icon, size: 20, color: enabled ? p.ink : p.muted),
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.remove_rounded, 'Fewer $label', value - 1, value > min),
        SizedBox(
          width: 44,
          child: AnimatedSwitcher(
            duration: Motion.short,
            transitionBuilder: (c, a) => ScaleTransition(
              scale: a,
              child: FadeTransition(opacity: a, child: c),
            ),
            child: Text(
              '$value',
              key: ValueKey(value),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        button(Icons.add_rounded, 'More $label', value + 1, value < max),
      ],
    );
  }
}

