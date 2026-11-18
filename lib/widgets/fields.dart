import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';

/// A labelled text field: the border warms to the accent on focus, and an
/// error slides in under it (and the field shakes) when [error] is set.
class LabeledField extends StatefulWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.hint,
    this.error,
    this.keyboardType,
    this.formatters = const [],
    this.textInputAction = TextInputAction.next,
    this.capitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hint, error;
  final TextInputType? keyboardType;
  final List<TextInputFormatter> formatters;
  final TextInputAction textInputAction;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged, onSubmitted;
  final Widget? trailing;

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  int _shakes = 0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void didUpdateWidget(LabeledField old) {
    super.didUpdateWidget(old);
    if (widget.error != null && widget.error != old.error) _shakes++;
  }

  @override
  void dispose() {
    _focus.removeListener(_changed);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final focused = _focus.hasFocus;
    final bad = widget.error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: text.labelMedium!.copyWith(color: bad ? p.error : (focused ? p.accentDeep : p.inkSoft))),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          key: ValueKey(_shakes),
          tween: Tween(begin: _shakes == 0 ? 1 : 0, end: 1),
          duration: Motion.shake,
          builder: (_, t, child) => Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 10 * (1 - t), 0), child: child),
          child: AnimatedContainer(
            duration: Motion.short,
            height: Tokens.fieldHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: focused ? p.card : p.field,
              borderRadius: BorderRadius.circular(Tokens.fieldRadius),
              border: Border.all(color: bad ? p.error : (focused ? p.accent : p.line), width: focused || bad ? 1.6 : 1),
              boxShadow: [BoxShadow(color: p.accent.withValues(alpha: focused ? 0.16 : 0), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.formatters,
                    textInputAction: widget.textInputAction,
                    textCapitalization: widget.capitalization,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    style: text.bodyLarge!.copyWith(color: p.ink, fontWeight: FontWeight.w600, letterSpacing: 0.4),
                    cursorColor: p.accent,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: text.bodyLarge!.copyWith(color: p.muted),
                    ),
                  ),
                ),
                ?widget.trailing,
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: Motion.short,
          curve: Motion.settle,
          child: bad
              ? Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Text(widget.error!, style: text.bodySmall!.copyWith(color: p.error)))
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Lets only digits through, then reformats them with [format] and keeps
/// the cursor at the end.
class DigitsFormatter extends TextInputFormatter {
  DigitsFormatter(this.format);

  final String Function(String digits) format;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final out = format(next.text.replaceAll(RegExp(r'\D'), ''));
    return TextEditingValue(text: out, selection: TextSelection.collapsed(offset: out.length));
  }
}
