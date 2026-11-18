import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../add_card/add_card_screen.dart';
import '../send/send_screen.dart';
import '../shell/shell.dart';

/// The balance, the card in front, quick actions and what moved lately.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool hidden = false;

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final balance = ref.watch(balanceProvider);
    final card = ref.watch(frontCardOfProvider);
    final recent = ref.watch(txnsProvider).take(5).toList();
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Tokens.gutter,
        MediaQuery.paddingOf(context).top + 12,
        Tokens.gutter,
        130,
      ),
      children: [
        Entrance(
          spacing: 22,
          children: [
            Row(
              children: [
                Avatar(name: seed.name, image: seed.avatar, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back', style: text.bodySmall),
                      Text(seed.firstName, style: text.titleLarge),
                    ],
                  ),
                ),
                RoundButton(
                  icon: hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  label: hidden ? 'Show balance' : 'Hide balance',
                  onTap: () => setState(() => hidden = !hidden),
                ),
              ],
            ),
            Column(
              children: [
                Text('Balance', style: text.bodyMedium),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedSwitcher(
                    duration: Motion.medium,
                    transitionBuilder: (c, a) => FadeTransition(
                      opacity: a,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.92, end: 1.0).animate(a),
                        child: c,
                      ),
                    ),
                    child: hidden
                        ? Text(
                            '••••••',
                            key: const ValueKey('hidden'),
                            style: text.displaySmall!.copyWith(
                              fontSize: 52,
                              color: p.ink,
                            ),
                          )
                        : RollingText(
                            money(balance),
                            key: const ValueKey('shown'),
                            style: text.displaySmall!.copyWith(
                              fontSize: 52,
                              color: p.ink,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                QuickAction(
                  icon: Icons.north_east_rounded,
                  label: 'Send',
                  filled: true,
                  onTap: () => context.open(const SendScreen()),
                ),
                QuickAction(
                  icon: Icons.add_card_rounded,
                  label: 'Add card',
                  onTap: () => context.open(const AddCardScreen()),
                ),
                QuickAction(
                  icon: Icons.credit_card_rounded,
                  label: 'Cards',
                  onTap: () => ref.read(tabProvider.notifier).state = 1,
                ),
              ],
            ),
            Center(
              child: GestureDetector(
                onTap: () => ref.read(tabProvider.notifier).state = 1,
                child: CardFace.of(
                  card,
                  holder: seed.name,
                  width: MediaQuery.sizeOf(context).width - Tokens.gutter * 2,
                ),
              ),
            ),
            SectionTitle(
              'Recent',
              action: 'See all',
              onAction: () => ref.read(tabProvider.notifier).state = 2,
            ),
            Column(
              children: [
                for (final t in recent)
                  TxnRow(
                    txn: t,
                    contact: t.contactId == null
                        ? null
                        : seed.contact(t.contactId!),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
