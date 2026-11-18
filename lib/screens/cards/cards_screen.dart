import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../add_card/add_card_screen.dart';

/// The wallet: flick through the cards, see the whole number, freeze one.
class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  bool reveal = false;
  bool freezing = false;

  Future<void> freeze(PayCard card, bool on) async {
    setState(() => freezing = true);
    await ref.read(cardsProvider.notifier).setFrozen(card.id, on);
    if (mounted) setState(() => freezing = false);
  }

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final cards = ref.watch(cardsProvider);
    final card = ref.watch(frontCardOfProvider);
    final spent = ref.watch(cardSpentProvider(card.id));
    final activity = ref.watch(txnsProvider).where((t) => t.cardId == card.id).take(4).toList();
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return ListView(
      padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 12, Tokens.gutter, 130),
      children: [
        Row(
          children: [
            Expanded(child: Text('Cards', style: text.headlineSmall)),
            RoundButton(icon: Icons.add_rounded, label: 'Add a card', onTap: () => context.open(const AddCardScreen())),
          ],
        ),
        Text('Flick the front card to see the next. ${cards.length} in your wallet.', style: text.bodyMedium),
        const SizedBox(height: 22),
        Center(
          child: CardStack(
            cards: cards,
            front: card.id,
            holder: seed.name,
            reveal: reveal,
            width: MediaQuery.sizeOf(context).width - Tokens.gutter * 2,
            onFront: (id) => setState(() {
              reveal = false;
              ref.read(frontCardProvider.notifier).state = id;
            }),
          ),
        ),
        const SizedBox(height: 22),
        Entrance(
          spacing: 16,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(duration: Motion.short, child: Text(card.name, key: ValueKey(card.id), style: text.titleLarge)),
                      Text('${card.kind} · ends ${card.last4} · ${card.expiry}', style: text.bodySmall),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => reveal = !reveal),
                  icon: Icon(reveal ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: p.accentDeep),
                  label: Text(reveal ? 'Hide number' : 'Show number', style: text.labelMedium!.copyWith(color: p.accentDeep)),
                ),
              ],
            ),
            LimitBar(spent: spent, limit: card.limitCents),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card.frozen ? p.accentWash : p.card.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: card.frozen ? p.accent : p.line),
              ),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: card.frozen ? 0.5 : 0,
                    duration: Motion.frost,
                    curve: Motion.settle,
                    child: Icon(Icons.ac_unit_rounded, color: card.frozen ? p.accentDeep : p.inkSoft),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.frozen ? 'Card frozen' : 'Freeze card', style: text.titleMedium),
                        Text(card.frozen ? 'Every payment is declined.' : 'Stops payments until you unfreeze it.', style: text.bodySmall),
                      ],
                    ),
                  ),
                  Switch(
                    value: card.frozen,
                    activeTrackColor: p.accent,
                    onChanged: freezing ? null : (on) => freeze(card, on),
                  ),
                ],
              ),
            ),
            SectionTitle(activity.isEmpty ? 'No payments yet' : 'Paid with this card'),
            Column(children: [for (final t in activity) TxnRow(txn: t)]),
          ],
        ),
      ],
    );
  }
}
