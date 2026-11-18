import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../shell/shell.dart';

/// A card that fills in as you type, and turns over for the security code.
class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final number = TextEditingController();
  final holder = TextEditingController();
  final expiry = TextEditingController();
  final cvv = TextEditingController();
  final label = TextEditingController();
  final cvvFocus = FocusNode();
  int tone = 1;
  bool tried = false, busy = false, done = false;

  @override
  void initState() {
    super.initState();
    cvvFocus.addListener(() => setState(() {}));
  }

  String? get numberError => luhn(number.text) ? null : 'That card number does not look right';
  String? get expiryError => expiryValid(expiry.text, ref.read(clockProvider)()) ? null : 'Use a month that has not passed, as MM/YY';
  String? get cvvError => cvv.text.length == 3 ? null : 'Three digits, on the back';

  Future<void> add() async {
    setState(() => tried = true);
    if (numberError != null || expiryError != null || cvvError != null) return;
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    await ref.read(cardsProvider.notifier).add(name: label.text, number: number.text, expiry: expiry.text, cvv: cvv.text, tone: tone);
    setState(() {
      busy = false;
      done = true;
    });
    await AppTiming.wait(AppTiming.successBeat);
    if (!mounted) return;
    ref.read(tabProvider.notifier).state = 1;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final width = MediaQuery.sizeOf(context).width - Tokens.gutter * 2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 8, Tokens.gutter, 130),
        children: [
          Row(
            children: [
              RoundButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 14),
              Text('Add a card', style: text.titleLarge),
            ],
          ),
          const SizedBox(height: 22),
          FlipCard(
            flipped: cvvFocus.hasFocus,
            front: CardFace(
              tone: tone,
              name: label.text.trim().isEmpty ? 'New card' : label.text.trim(),
              number: number.text,
              expiry: expiry.text,
              holder: holder.text,
              masked: false,
              width: width,
            ),
            back: CardBack(tone: tone, cvv: cvv.text, width: width, highlight: cvvFocus.hasFocus),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var t = 0; t < CardTones.count; t++)
                Semantics(
                  button: true,
                  selected: t == tone,
                  label: 'Card colour ${t + 1}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => setState(() => tone = t),
                    child: AnimatedContainer(
                      duration: Motion.medium,
                      curve: Motion.spring,
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      width: t == tone ? 40 : 32,
                      height: t == tone ? 40 : 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: CardTones.of(t)),
                        border: Border.all(color: t == tone ? p.ink : Colors.transparent, width: 2.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Entrance(
            spacing: 14,
            children: [
              LabeledField(
                label: 'Card number',
                controller: number,
                hint: '0000 0000 0000 0000',
                keyboardType: TextInputType.number,
                formatters: [DigitsFormatter(groupCardNumber)],
                error: tried ? numberError : null,
                onChanged: (_) => setState(() {}),
              ),
              LabeledField(
                label: 'Name on card',
                controller: holder,
                hint: 'As it is printed',
                capitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledField(
                      label: 'Expires',
                      controller: expiry,
                      hint: 'MM/YY',
                      keyboardType: TextInputType.number,
                      formatters: [DigitsFormatter(formatExpiry)],
                      error: tried ? expiryError : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledField(
                      label: 'Security code',
                      controller: cvv,
                      focusNode: cvvFocus,
                      hint: '123',
                      keyboardType: TextInputType.number,
                      formatters: [DigitsFormatter((d) => d.length > 3 ? d.substring(0, 3) : d)],
                      error: tried ? cvvError : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              LabeledField(
                label: 'Call it',
                controller: label,
                hint: 'Groceries, Travel, Rent',
                capitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              TallyButton(label: 'Add card', icon: Icons.add_card_rounded, busy: busy, done: done, onPressed: busy || done ? null : add),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    number.dispose();
    holder.dispose();
    expiry.dispose();
    cvv.dispose();
    label.dispose();
    cvvFocus.dispose();
    super.dispose();
  }
}
