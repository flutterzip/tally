import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/config/timing.dart';
import 'package:tally/data/models.dart';
import 'package:tally/state/store.dart';

import '../helpers.dart';

void main() {
  setUp(() => AppTiming.scale = 0);

  group('money', () {
    test('formats cents with grouping and sign', () {
      expect(money(124826), '\$1,248.26');
      expect(money(-640), '-\$6.40');
      expect(money(3000, sign: true), '+\$30.00');
      expect(money(500000, whole: true), '\$5,000');
      expect(money(5), '\$0.05');
    });

    test('the keypad builds amounts and refuses what it should', () {
      var s = '';
      for (final k in ['4', '5', '.', '5']) {
        s = pressKey(s, k);
      }
      expect(s, '45.5');
      expect(centsOf(s), 4550);
      expect(pressKey('45.50', '1'), '45.50');
      expect(pressKey('45.5', '.'), '45.5');
      expect(pressKey('99999', '1'), '99999');
      expect(pressKey('0', '7'), '7');
      expect(pressKey('', '.'), '0.');
      expect(pressKey('12', '<'), '1');
      expect(centsOf(''), 0);
    });
  });

  group('cards', () {
    test('number, expiry and Luhn', () {
      expect(groupCardNumber('42424242424242429999'), '4242 4242 4242 4242');
      expect(formatExpiry('0829'), '08/29');
      expect(formatExpiry('1'), '1');
      expect(luhn('4242 4242 4242 4242'), isTrue);
      expect(luhn('4242 4242 4242 4241'), isFalse);
      expect(expiryValid('08/29', testNow), isTrue);
      expect(expiryValid('10/26', testNow), isFalse);
      expect(expiryValid('13/30', testNow), isFalse);
    });

    test('freeze, add to the front, and saved', () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final c = makeContainer(sp, TestClock());
      addTearDown(c.dispose);
      await c.read(cardsProvider.notifier).setFrozen('travel', true);
      expect(c.read(cardsProvider).firstWhere((x) => x.id == 'travel').frozen, isTrue);
      final card = await c.read(cardsProvider.notifier).add(name: 'Groceries', number: '4242424242424242', expiry: '09/30', cvv: '123', tone: 3);
      expect(c.read(cardsProvider).first.id, card.id);
      expect(c.read(frontCardOfProvider).name, 'Groceries');
      expect(card.number, '4242 4242 4242 4242');
      final again = makeContainer(sp, TestClock());
      addTearDown(again.dispose);
      expect(again.read(cardsProvider).length, 3);
      expect(again.read(cardsProvider).firstWhere((x) => x.id == 'travel').frozen, isTrue);
    });
  });

  group('activity', () {
    test('balance is the opening plus every movement', () async {
      SharedPreferences.setMockInitialValues({});
      final c = makeContainer(await SharedPreferences.getInstance(), TestClock());
      addTearDown(c.dispose);
      expect(c.read(balanceProvider), 100000 - 640 + 20000 - 4500 - 2400);
    });

    test('sending takes it off the balance, is saved, and refuses too much', () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final c = makeContainer(sp, TestClock());
      addTearDown(c.dispose);
      final before = c.read(balanceProvider);
      final txn = await c.read(txnsProvider.notifier).send(testSeed.contact('ada'), 4550, note: ' Lunch ');
      expect(txn.cents, -4550);
      expect(txn.note, 'Lunch');
      expect(c.read(balanceProvider), before - 4550);
      expect(c.read(txnsProvider).first.id, txn.id);
      await expectLater(c.read(txnsProvider.notifier).send(testSeed.contact('ada'), before), throwsStateError);
      final again = makeContainer(sp, TestClock());
      addTearDown(again.dispose);
      expect(again.read(balanceProvider), before - 4550);
    });

    test('the week and categories', () async {
      SharedPreferences.setMockInitialValues({});
      final c = makeContainer(await SharedPreferences.getInstance(), TestClock());
      addTearDown(c.dispose);
      final week = c.read(weekProvider);
      expect(week.length, 7);
      expect(week.last.spent, 640);
      expect(week[4].spent, 4500);
      final cats = c.read(byCategoryProvider);
      expect(cats.first.category, Category.fun);
      expect(cats.map((e) => e.category), isNot(contains(Category.transfer)));
      expect(c.read(cardSpentProvider('everyday')), 640);
    });

    test('a receipt reference is stable', () {
      final t = Txn(id: 'sent-1', title: 'x', category: Category.transfer, cents: -1, at: testNow);
      expect(t.ref, t.ref);
      expect(t.ref, startsWith('TL'));
      expect(t.ref.length, 10);
    });
  });
}
