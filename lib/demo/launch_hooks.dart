import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/add_card/add_card_screen.dart';
import '../screens/receipt/receipt_screen.dart';
import '../screens/send/send_screen.dart';
import '../screens/shell/shell.dart';
import '../state/store.dart';
import '../widgets/routes.dart';

/// Opens a screen straight after the splash, for screenshots and
/// recordings: `--dart-define=startRoute=send`. Off by default, so a
/// release build is unaffected.
///
/// send, receipt (for the latest payment to someone), add_card, cards,
/// activity.
const startRoute = String.fromEnvironment('startRoute');

void runLaunchHooks(WidgetRef ref) {
  switch (startRoute) {
    case 'send':
      homeNavigator.currentState?.push(TallyRoute(const SendScreen()));
    case 'receipt':
      final txn = ref.read(txnsProvider).firstWhere((t) => t.contactId != null && t.cents < 0);
      homeNavigator.currentState?.push(TallyRoute(ReceiptScreen(txn: txn)));
    case 'add_card':
      homeNavigator.currentState?.push(TallyRoute(const AddCardScreen()));
    case 'cards':
      ref.read(tabProvider.notifier).state = 1;
    case 'activity':
      ref.read(tabProvider.notifier).state = 2;
  }
}
