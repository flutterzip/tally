import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/config/motion.dart';
import 'package:tally/config/theme.dart';
import 'package:tally/config/timing.dart';
import 'package:tally/data/models.dart';
import 'package:tally/state/store.dart';
import 'package:tally/widgets/backdrop.dart';

final testNow = DateTime(2026, 11, 18, 9, 41);

const testSeed = Seed(
  name: 'Olympicson',
  openingCents: 100000,
  cards: [
    PayCard(id: 'everyday', name: 'Everyday', kind: 'Debit', number: '4929 1840 5521 7304', expiry: '08/29', cvv: '318', tone: 0, limitCents: 300000),
    PayCard(id: 'travel', name: 'Travel', kind: 'Credit', number: '5412 7700 3195 2286', expiry: '02/28', cvv: '604', tone: 2, limitCents: 500000),
  ],
  contacts: [
    Contact(id: 'ada', name: 'Ada Nwosu', handle: '@ada', tone: 0),
    Contact(id: 'kemi', name: 'Kemi Adeyemi', handle: '@kemi.a', tone: 2),
  ],
  txns: [
    {'id': 's1', 'title': 'Bean & Leaf', 'category': 'food', 'cents': -640, 'daysAgo': 0, 'hour': 8, 'card': 'everyday'},
    {'id': 's2', 'title': 'Salary', 'category': 'income', 'cents': 20000, 'daysAgo': 1, 'hour': 9},
    {'id': 's3', 'title': 'Kemi Adeyemi', 'category': 'transfer', 'cents': -4500, 'daysAgo': 2, 'hour': 19, 'contact': 'kemi', 'note': 'Dinner'},
    {'id': 's4', 'title': 'Cinema Nine', 'category': 'fun', 'cents': -2400, 'daysAgo': 3, 'hour': 21, 'card': 'travel'},
  ],
);

class TestClock {
  DateTime now = testNow;
}

ProviderContainer makeContainer(SharedPreferences sp, TestClock clock) => ProviderContainer(overrides: [
      prefsProvider.overrideWithValue(sp),
      seedProvider.overrideWithValue(testSeed),
      clockProvider.overrideWithValue(() => clock.now),
    ]);

Future<(ProviderContainer, TestClock)> pumpScreen(WidgetTester tester, Widget screen, {Map<String, Object> prefs = const {}}) async {
  Motion.ambient = false;
  AppTiming.scale = 0;
  tester.view.physicalSize = const Size(1320, 2868);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final clock = TestClock();
  final container = makeContainer(sp, clock);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => PaperBackdrop(child: child!),
      home: Material(type: MaterialType.transparency, child: screen),
    ),
  ));
  await tester.pumpAndSettle();
  return (container, clock);
}
