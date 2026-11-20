import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';

/// Where the money went this week: a bar per day, the biggest categories,
/// and every movement by day.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  int day = 6;
  Category? only;
  final scroll = ScrollController();

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final week = ref.watch(weekProvider);
    final cats = ref.watch(byCategoryProvider);
    final today = ref.watch(clockProvider)();
    final total = week.fold(0, (s, d) => s + d.spent);
    final txns = ref.watch(txnsProvider).where((t) => only == null || t.category == only).toList();
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return Stack(
      children: [
        ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(Tokens.gutter, TopChrome.extent(context, bottomHeight: 58) + 6, Tokens.gutter, 130),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: p.card.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(Tokens.cardRadius), border: Border.all(color: p.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day == 6 ? 'Spent today' : 'Spent on ${dayLabel(week[day].day, today)}', style: text.bodyMedium),
                  RollingText(money(week[day].spent), style: text.displaySmall!.copyWith(fontSize: 40, color: p.ink)),
                  Text('${money(total)} in the last seven days', style: text.bodySmall),
                  const SizedBox(height: 18),
                  SpendBars(days: week, selected: day, onSelect: (i) => setState(() => day = i)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final (i, t) in txns.indexed) ...[
              if (i == 0 || dateOnly(txns[i - 1].at) != dateOnly(t.at))
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 4),
                  child: Text(dayLabel(t.at, today), style: text.labelMedium!.copyWith(color: p.muted)),
                ),
              AnimatedSwitcher(
                duration: Motion.medium,
                child: TxnRow(key: ValueKey(t.id), txn: t, contact: t.contactId == null ? null : seed.contact(t.contactId!)),
              ),
            ],
          ],
        ),
        // The filters stay in reach: they hide while you read down and come
        // back the moment you scroll up.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TopChrome(
            controller: scroll,
            row: Align(alignment: Alignment.centerLeft, child: Text('Activity', style: text.headlineSmall)),
            bottomHeight: 58,
            bottom: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
                  children: [
                    for (final c in [null, ...cats.map((e) => e.category)])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c == null ? 'All' : '${c.label} ${money(cats.firstWhere((e) => e.category == c).spent, whole: true)}'),
                          avatar: c == null ? null : Icon(c.icon, size: 16, color: only == c ? p.onAccent : p.inkSoft),
                          showCheckmark: false,
                          selected: only == c,
                          selectedColor: p.accent,
                          backgroundColor: p.card,
                          side: BorderSide(color: only == c ? p.accent : p.line),
                          shape: const StadiumBorder(),
                          labelStyle: text.labelMedium!.copyWith(color: only == c ? p.onAccent : p.ink),
                          onSelected: (_) => setState(() => only = c),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
