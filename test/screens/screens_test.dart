import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/screens/activity/activity_screen.dart';
import 'package:tally/screens/add_card/add_card_screen.dart';
import 'package:tally/screens/cards/cards_screen.dart';
import 'package:tally/screens/home/home_screen.dart';
import 'package:tally/screens/receipt/receipt_screen.dart';
import 'package:tally/screens/send/send_screen.dart';
import 'package:tally/state/store.dart';
import 'package:tally/widgets/widgets.dart';

import '../helpers.dart';

Future<void> key(WidgetTester t, String k) async {
  await t.tap(find.descendant(of: find.byType(Keypad), matching: find.text(k)));
  await t.pump();
}

void main() {
  testWidgets('Home: balance, card, recent, and hiding the balance', (t) async {
    final (c, _) = await pumpScreen(t, const HomeScreen());
    expect(find.byType(RollingText), findsOneWidget);
    expect(find.byType(CardFace), findsOneWidget);
    expect(find.byType(TxnRow), findsNWidgets(4));
    await t.tap(find.byType(RoundButton));
    await t.pumpAndSettle();
    expect(find.text('••••••'), findsOneWidget);
    expect(c.read(balanceProvider), 112460);
  });

  group('Send', () {
    testWidgets('needs someone and an amount, then slides to send', (t) async {
      final (c, _) = await pumpScreen(t, const SendScreen());
      expect(t.widget<SlideToPay>(find.byType(SlideToPay)).enabled, isFalse);
      await t.tap(find.byType(ContactBubble).first);
      for (final k in ['4', '5', '.', '5']) {
        await key(t, k);
      }
      await t.pumpAndSettle();
      expect(find.text('Slide to send \$45.50'), findsOneWidget);
      final slider = t.widget<SlideToPay>(find.byType(SlideToPay));
      expect(slider.enabled, isTrue);
      final before = c.read(balanceProvider);
      slider.onSlid();
      await t.pumpAndSettle();
      expect(c.read(balanceProvider), before - 4550);
    });

    testWidgets('refuses more than the balance', (t) async {
      await pumpScreen(t, const SendScreen());
      await t.tap(find.byType(ContactBubble).first);
      for (final k in ['9', '9', '9', '9', '9']) {
        await key(t, k);
      }
      await t.pumpAndSettle();
      expect(find.textContaining('More than your balance'), findsOneWidget);
      expect(t.widget<SlideToPay>(find.byType(SlideToPay)).enabled, isFalse);
    });

    testWidgets('a third decimal is refused with a shake', (t) async {
      await pumpScreen(t, const SendScreen());
      for (final k in ['1', '.', '2', '5', '9']) {
        await key(t, k);
      }
      await t.pumpAndSettle();
      expect(t.widget<AmountDisplay>(find.byType(AmountDisplay)).typed, '1.25');
      expect(t.widget<AmountDisplay>(find.byType(AmountDisplay)).shake, 1);
    });
  });

  testWidgets('Receipt prints the payment and offers Done', (t) async {
    final txn = Txn(id: 'sent-1', title: 'Kemi Adeyemi', category: Category.transfer, cents: -4550, at: testNow, contactId: 'kemi');
    await pumpScreen(t, ReceiptScreen(txn: txn));
    expect(find.text('\$45.50'), findsOneWidget);
    expect(find.text('Kemi Adeyemi @kemi.a'), findsOneWidget);
    expect(find.text(txn.ref), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  group('Cards', () {
    testWidgets('freeze the front card', (t) async {
      final (c, _) = await pumpScreen(t, const CardsScreen());
      expect(find.byType(CardStack), findsOneWidget);
      await t.tap(find.byType(Switch));
      await t.pumpAndSettle();
      expect(c.read(cardsProvider).first.frozen, isTrue);
      expect(find.text('Card frozen'), findsOneWidget);
    });

    testWidgets('show the whole number', (t) async {
      await pumpScreen(t, const CardsScreen());
      expect(find.text('9'), findsNothing);
      await t.tap(find.text('Show number'));
      await t.pumpAndSettle();
      expect(find.text('Hide number'), findsOneWidget);
      expect(find.text('9'), findsWidgets);
    });

    testWidgets('flick the front card to bring the next', (t) async {
      final (c, _) = await pumpScreen(t, const CardsScreen());
      await t.fling(find.byType(CardFace).last, const Offset(-400, 0), 2000);
      await t.pumpAndSettle();
      expect(c.read(frontCardOfProvider).id, 'travel');
    });
  });

  group('Add card', () {
    testWidgets('flags a bad number, turns over for the code, then adds', (t) async {
      final (c, _) = await pumpScreen(t, const Scaffold(body: AddCardScreen()));
      final fields = find.byType(TextField);
      await t.enterText(fields.at(0), '4242424242424241');
      await t.enterText(fields.at(2), '0930');
      await t.enterText(fields.at(3), '123');
      await t.ensureVisible(find.text('Add card').last);
      await t.tap(find.text('Add card').last);
      await t.pumpAndSettle();
      expect(find.text('That card number does not look right'), findsOneWidget);
      expect(c.read(cardsProvider).length, 2);

      await t.tap(fields.at(3));
      await t.pumpAndSettle();
      expect(find.byType(CardBack), findsOneWidget);

      await t.enterText(fields.at(0), '4242424242424242');
      await t.enterText(fields.at(4), 'Groceries');
      await t.tap(find.text('Add card').last);
      await t.pumpAndSettle();
      expect(c.read(cardsProvider).length, 3);
      expect(c.read(cardsProvider).first.name, 'Groceries');
      expect(c.read(cardsProvider).first.number, '4242 4242 4242 4242');
    });
  });

  testWidgets('Activity: the week, a day, and a category filter', (t) async {
    await pumpScreen(t, const ActivityScreen());
    expect(find.byType(SpendBars), findsOneWidget);
    expect(find.text('Spent today'), findsOneWidget);
    expect(find.byType(TxnRow), findsNWidgets(4));
    await t.tap(find.byType(ChoiceChip).at(1));
    await t.pumpAndSettle();
    expect(find.byType(TxnRow), findsOneWidget);
  });
}
