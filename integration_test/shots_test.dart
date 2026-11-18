// Screenshots of every screen on the simulator, light and dark:
//   tool/shots.sh
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/app.dart';
import 'package:tally/demo/demo_control.dart';
import 'package:tally/screens/add_card/add_card_screen.dart';
import 'package:tally/screens/send/send_screen.dart';
import 'package:tally/screens/shell/shell.dart';
import 'package:tally/state/store.dart';
import 'package:tally/widgets/widgets.dart';

const mode = String.fromEnvironment('mode', defaultValue: 'light');

Future<void> settle(WidgetTester t, [int ms = 1600]) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('shots $mode', (t) async {
    DemoControl.enabled = false;
    SharedPreferences.setMockInitialValues({'tally.theme.v1': mode});
    final prefs = await SharedPreferences.getInstance();
    final seed = await Seed.load();
    final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs), seedProvider.overrideWithValue(seed)]);
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const TallyApp(splash: false)));
    await settle(t, 2500);
    Future<void> shot(String name, [int ms = 1600]) async {
      await settle(t, ms);
      await binding.takeScreenshot('${name}_$mode');
    }

    await shot('home', 2200);

    homeNavigator.currentState!.push(TallyRoute(const SendScreen()));
    await settle(t, 1200);
    await t.tap(find.byType(ContactBubble).at(2));
    for (final k in ['4', '5', '.', '5']) {
      await t.tap(find.text(k).last);
      await settle(t, 120);
    }
    await shot('send', 1000);
    final slider = find.byType(SlideToPay);
    final r = t.getRect(slider);
    await t.dragFrom(Offset(r.left + 34, r.center.dy), Offset(r.width, 0));
    await shot('receipt_printing', 2400);
    await shot('receipt', 4200);
    homeNavigator.currentState!.popUntil((r) => r.isFirst);
    await settle(t, 700);

    c.read(tabProvider.notifier).state = 1;
    await shot('cards', 2000);
    c.read(frontCardProvider.notifier).state = 'online';
    await shot('cards_frozen', 2200);
    c.read(frontCardProvider.notifier).state = 'everyday';
    await settle(t, 900);
    await t.tap(find.text('Show number'));
    await shot('cards_reveal', 1400);

    homeNavigator.currentState!.push(TallyRoute(const AddCardScreen()));
    c.read(tabProvider.notifier).state = 0;
    await settle(t, 1200);
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), '4242424242424242');
    await t.enterText(fields.at(1), 'Olympicson');
    await t.enterText(fields.at(2), '0930');
    await shot('add_card', 1400);
    await t.tap(fields.at(3));
    await t.enterText(fields.at(3), '12');
    await shot('add_card_back', 1400);
    FocusManager.instance.primaryFocus?.unfocus();
    homeNavigator.currentState!.popUntil((r) => r.isFirst);
    await settle(t, 700);

    c.read(tabProvider.notifier).state = 2;
    await shot('activity', 2200);
  });
}
