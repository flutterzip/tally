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
  final scroll = ScrollController();

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

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
    final p = context.palette;
    // The device's own inset: the tab bar slides away on this page.
    final safe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Who to pay at the top, the amount in the middle, the keypad
          // just above the slider; it scrolls only when the screen is short.
          CustomScrollView(
            controller: scroll,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(Tokens.gutter, TopChrome.extent(context) + 4, Tokens.gutter, 0),
                sliver: SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
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
                      const Spacer(),
                      const SizedBox(height: 14),
                      AmountDisplay(
                        typed: typed,
                        shake: shakes,
                        note: over ? 'More than your balance of ${money(balance)}' : 'Balance ${money(balance)}',
                      ),
                      const Spacer(),
                      const SizedBox(height: 10),
                      Keypad(onKey: press),
                      // Room for the slider docked below.
                      SizedBox(height: safe + 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // The keypad fades into the paper under the slider.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: safe + 110,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [p.paper.withValues(alpha: 0), p.paper.withValues(alpha: 0.9), p.paper],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: Tokens.gutter,
            right: Tokens.gutter,
            bottom: safe + 12,
            // Sent: the slider breaks apart and flies together as the
            // payment, then the receipt prints.
            child: ParticleMorph(
              duration: Motion.morph,
              child: done
                  ? DonePill(key: const ValueKey('sent'), height: 68, label: 'Sent ${money(cents)} to ${to!.firstName}')
                  : SlideToPay(
                      key: const ValueKey('slide'),
                      label: to == null ? 'Pick someone to pay' : 'Slide to send ${money(cents)}',
                      enabled: to != null && cents > 0 && !over,
                      busy: busy,
                      onSlid: send,
                    ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopChrome(
              controller: scroll,
              row: Row(
                children: [
                  RoundButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 14),
                  Text('Send money', style: text.titleLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
