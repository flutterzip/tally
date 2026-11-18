import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';

/// The receipt printing out after money is sent, then a way back.
class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key, required this.txn});

  final Txn txn;

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool printed = false;

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final txn = widget.txn;
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 18, Tokens.gutter, 130),
        children: [
          Text('Money sent', textAlign: TextAlign.center, style: text.headlineSmall),
          Text('${txn.title} has it now.', textAlign: TextAlign.center, style: text.bodyMedium),
          const SizedBox(height: 24),
          PrintedReceipt(
            title: 'Payment to ${txn.title}',
            amount: money(-txn.cents),
            code: txn.ref,
            lines: [
              ('To', txn.contactId == null ? txn.title : '${txn.title} ${seed.contact(txn.contactId!).handle}'),
              if (txn.note != null) ('Note', txn.note!),
              ('From', 'Tally balance'),
              ('Date', stamp(txn.at)),
              ('Fee', money(0)),
            ],
            onPrinted: () => setState(() => printed = true),
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            duration: Motion.medium,
            opacity: printed ? 1 : 0,
            child: AnimatedSlide(
              duration: Motion.medium,
              curve: Motion.settle,
              offset: printed ? Offset.zero : const Offset(0, 0.4),
              child: Column(
                children: [
                  TallyButton(label: 'Done', onPressed: printed ? () => Navigator.of(context).pop() : null),
                  const SizedBox(height: 10),
                  Text('Balance now ${money(ref.watch(balanceProvider))}', style: text.bodySmall!.copyWith(color: p.inkSoft)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
