import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../receipt/receipt_screen.dart';

/// Pick someone, type an amount, slide to send.
class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  Contact? to;
  String typed = '';
  int shakes = 0;
  bool busy = false, done = false;

  void press(String key) {
    final next = pressKey(typed, key);
    if (next == typed && key != '<') {
      setState(() => shakes++);
      return;
    }
    setState(() => typed = next);
  }

  Future<void> send() async {
    final cents = centsOf(typed);
    setState(() => busy = true);
    try {
      final txn = await ref.read(txnsProvider.notifier).send(to!, cents);
      setState(() => done = true);
      await AppTiming.wait(AppTiming.successBeat);
      if (mounted) context.swap(ReceiptScreen(txn: txn));
    } on StateError {
      setState(() => shakes++);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final balance = ref.watch(balanceProvider);
    final cents = centsOf(typed);
    final over = cents > balance;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 8, Tokens.gutter, 120),
        children: [
          Row(
            children: [
              RoundButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 14),
              Text('Send money', style: text.titleLarge),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in seed.contacts)
                  ContactBubble(contact: c, selected: c == to, onTap: () => setState(() => to = c)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AmountDisplay(
            typed: typed,
            shake: shakes,
            note: over ? 'More than your balance of ${money(balance)}' : 'Balance ${money(balance)}',
          ),
          const SizedBox(height: 10),
          Keypad(onKey: press),
          const SizedBox(height: 14),
          SlideToPay(
            label: to == null ? 'Pick someone to pay' : 'Slide to send ${money(cents)}',
            enabled: to != null && cents > 0 && !over,
            busy: busy,
            done: done,
            onSlid: send,
          ),
        ],
      ),
    );
  }
}
