// Drives the real app on the simulator at human speed, for recording and
// for judging motion frame by frame:   tool/rec.sh pay
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/app.dart';
import 'package:tally/state/store.dart';
import 'package:tally/widgets/widgets.dart';

Future<void> pause(WidgetTester t, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

Future<void> typeInto(WidgetTester t, Finder field, String text) async {
  await t.tap(field);
  await pause(t, 300);
  for (var i = 1; i <= text.length; i++) {
    await t.enterText(field, text.substring(0, i));
    await pause(t, 90);
  }
}

/// Drags in small steps so the motion is visible on the recording.
Future<void> slide(WidgetTester t, Offset from, Offset by, {int steps = 24}) async {
  final g = await t.startGesture(from);
  for (var i = 1; i <= steps; i++) {
    await g.moveTo(from + by * (i / steps));
    await pause(t, 22);
  }
  await g.up();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('showreel', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final seed = await Seed.load();
    await t.pumpWidget(ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs), seedProvider.overrideWithValue(seed)],
      child: const TallyApp(),
    ));
    await pause(t, 5000);

    // Send money, watch the receipt print.
    await t.tap(find.text('Send'));
    await pause(t, 1400);
    await t.tap(find.byType(ContactBubble).at(2));
    await pause(t, 600);
    for (final k in ['4', '5', '.', '5', '0']) {
      await t.tap(find.text(k).last);
      await pause(t, 260);
    }
    await pause(t, 600);
    final r = t.getRect(find.byType(SlideToPay));
    await slide(t, Offset(r.left + 34, r.center.dy), Offset(r.width - 40, 0), steps: 30);
    await pause(t, 6500);
    await t.tap(find.text('Done'));
    await pause(t, 1800);

    // Cards: flick through, freeze, show the number.
    await t.tap(find.byIcon(Icons.credit_card_outlined));
    await pause(t, 1800);
    final stack = t.getRect(find.byType(CardStack));
    await slide(t, Offset(stack.center.dx, stack.bottom - 60), const Offset(-260, 0), steps: 14);
    await pause(t, 1400);
    await t.tap(find.byType(Switch));
    await pause(t, 2200);
    await t.tap(find.byType(Switch));
    await pause(t, 1800);
    await slide(t, Offset(stack.center.dx, stack.bottom - 60), const Offset(260, 0), steps: 14);
    await pause(t, 1200);
    await slide(t, Offset(stack.center.dx, stack.bottom - 60), const Offset(260, 0), steps: 14);
    await pause(t, 1200);
    await t.tap(find.text('Show number'));
    await pause(t, 1600);

    // Add a card: it fills in as you type and turns over for the code.
    await t.tap(find.byIcon(Icons.add_rounded));
    await pause(t, 1400);
    final fields = find.byType(TextField);
    await typeInto(t, fields.at(0), '4242424242424242');
    await typeInto(t, fields.at(1), 'Olympicson');
    await typeInto(t, fields.at(2), '0930');
    await pause(t, 400);
    await typeInto(t, fields.at(3), '123');
    await pause(t, 1200);
    await typeInto(t, fields.at(4), 'Groceries');
    await pause(t, 500);
    FocusManager.instance.primaryFocus?.unfocus();
    await pause(t, 900);
    await t.drag(find.byType(ListView).last, const Offset(0, 400));
    await pause(t, 700);
    for (final tone in ['Card colour 4', 'Card colour 3']) {
      await t.tap(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == tone));
      await pause(t, 900);
    }
    await t.ensureVisible(find.text('Add card'));
    await pause(t, 500);
    await t.tap(find.text('Add card'));
    await pause(t, 3200);

    await t.tap(find.byIcon(Icons.bar_chart_outlined));
    await pause(t, 1600);
    for (final i in [3, 1, 6]) {
      final b = t.getRect(find.byType(SpendBars));
      await t.tapAt(Offset(b.left + b.width * (i + 0.5) / 7, b.bottom - 60));
      await pause(t, 1100);
    }
    await pause(t, 1200);
  });
}
