import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/timing.dart';
import '../data/models.dart';

class Seed {
  const Seed({
    required this.name,
    required this.openingCents,
    required this.cards,
    required this.contacts,
    required this.txns,
    this.avatar,
  });

  final String name;
  final String? avatar;

  /// The balance before the seeded activity.
  final int openingCents;
  final List<PayCard> cards;
  final List<Contact> contacts;

  /// (id, title, category, cents, days ago, hour, card, contact, note)
  final List<Map<String, Object?>> txns;

  String get firstName => name.split(' ').first;

  Contact contact(String id) => contacts.firstWhere((c) => c.id == id);

  static Future<Seed> load([AssetBundle? bundle]) async {
    final j = jsonDecode(await (bundle ?? rootBundle).loadString('assets/data/wallet.json')) as Map<String, Object?>;
    return Seed(
      name: j['name'] as String,
      avatar: j['avatar'] as String?,
      openingCents: j['openingCents'] as int,
      cards: [for (final c in j['cards'] as List) PayCard.fromJson(c as Map<String, Object?>)],
      contacts: [for (final c in j['contacts'] as List) Contact.fromJson(c as Map<String, Object?>)],
      txns: [for (final t in j['transactions'] as List) t as Map<String, Object?>],
    );
  }
}

final seedProvider = Provider<Seed>((_) => throw UnimplementedError());
final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

// ------------------------------------------------------------ cards

final cardsProvider = NotifierProvider<CardsNotifier, List<PayCard>>(CardsNotifier.new);

class CardsNotifier extends Notifier<List<PayCard>> {
  static const _key = 'tally.cards.v1';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  List<PayCard> build() {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        return [for (final c in jsonDecode(raw) as List) PayCard.fromJson(c as Map<String, Object?>)];
      } catch (_) {}
    }
    return ref.read(seedProvider).cards;
  }

  void _save(List<PayCard> next) {
    state = next;
    _prefs.setString(_key, jsonEncode([for (final c in next) c.toJson()]));
  }

  PayCard byId(String id) => state.firstWhere((c) => c.id == id);

  /// Freezes or unfreezes a card. Frozen cards decline every payment.
  Future<void> setFrozen(String id, bool frozen) async {
    await AppTiming.wait(AppTiming.freeze);
    _save([for (final c in state) c.id == id ? c.copyWith(frozen: frozen) : c]);
  }

  /// Adds a card to the front of the wallet and hands it back.
  Future<PayCard> add({required String name, required String number, required String expiry, required String cvv, required int tone}) async {
    await AppTiming.wait(AppTiming.addCard);
    final card = PayCard(
      id: 'card-${ref.read(clockProvider)().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'New card' : name.trim(),
      kind: 'Debit',
      number: groupCardNumber(number),
      expiry: expiry,
      cvv: cvv,
      tone: tone,
      limitCents: 200000,
    );
    _save([card, ...state]);
    ref.read(frontCardProvider.notifier).state = card.id;
    return card;
  }
}

/// The card at the front of the wallet.
final frontCardProvider = StateProvider<String?>((ref) => null);

final frontCardOfProvider = Provider<PayCard>((ref) {
  final cards = ref.watch(cardsProvider);
  final id = ref.watch(frontCardProvider);
  return cards.firstWhere((c) => c.id == id, orElse: () => cards.first);
});

// ------------------------------------------------------------ activity

final txnsProvider = NotifierProvider<TxnsNotifier, List<Txn>>(TxnsNotifier.new);

class TxnsNotifier extends Notifier<List<Txn>> {
  static const _key = 'tally.sent.v1';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  /// Seeded activity, dated relative to today so the demo never goes stale.
  List<Txn> _seeded() {
    final today = dateOnly(ref.read(clockProvider)());
    return [
      for (final t in ref.read(seedProvider).txns)
        Txn(
          id: t['id'] as String,
          title: t['title'] as String,
          category: Category.values.byName(t['category'] as String),
          cents: t['cents'] as int,
          at: today.subtract(Duration(days: t['daysAgo'] as int)).add(Duration(hours: t['hour'] as int, minutes: 12)),
          cardId: t['card'] as String?,
          contactId: t['contact'] as String?,
          note: t['note'] as String?,
        ),
    ];
  }

  @override
  List<Txn> build() {
    final raw = _prefs.getString(_key);
    var sent = <Txn>[];
    if (raw != null) {
      try {
        sent = [for (final t in jsonDecode(raw) as List) Txn.fromJson(t as Map<String, Object?>)];
      } catch (_) {}
    }
    return [...sent, ..._seeded()]..sort((a, b) => b.at.compareTo(a.at));
  }

  /// Sends money to a contact and hands back the transaction for the
  /// receipt. Throws [StateError] if it is more than the balance.
  Future<Txn> send(Contact to, int cents, {String? note}) async {
    if (cents <= 0) throw ArgumentError.value(cents, 'cents');
    final balance = state.fold(ref.read(seedProvider).openingCents, (sum, t) => sum + t.cents);
    if (cents > balance) throw StateError('Not enough money');
    await AppTiming.wait(AppTiming.pay);
    final now = ref.read(clockProvider)();
    final txn = Txn(
      id: 'sent-${now.microsecondsSinceEpoch}',
      title: to.name,
      category: Category.transfer,
      cents: -cents,
      at: now,
      contactId: to.id,
      note: note == null || note.trim().isEmpty ? null : note.trim(),
    );
    state = [txn, ...state];
    final mine = state.where((t) => t.id.startsWith('sent-')).toList();
    await _prefs.setString(_key, jsonEncode([for (final t in mine) t.toJson()]));
    return txn;
  }
}

final balanceProvider = Provider<int>((ref) {
  final seed = ref.watch(seedProvider);
  return ref.watch(txnsProvider).fold(seed.openingCents, (sum, t) => sum + t.cents);
});

/// Money in and out over the last seven days, today last.
final weekProvider = Provider<List<({DateTime day, int spent})>>((ref) {
  final today = dateOnly(ref.watch(clockProvider)());
  final txns = ref.watch(txnsProvider);
  return [
    for (var i = 6; i >= 0; i--)
      (
        day: today.subtract(Duration(days: i)),
        spent: txns
            .where((t) => t.cents < 0 && dateOnly(t.at) == today.subtract(Duration(days: i)))
            .fold(0, (sum, t) => sum - t.cents),
      ),
  ];
});

/// Spent this week per spending category, biggest first.
final byCategoryProvider = Provider<List<({Category category, int spent})>>((ref) {
  final from = dateOnly(ref.watch(clockProvider)()).subtract(const Duration(days: 6));
  final txns = ref.watch(txnsProvider).where((t) => t.cents < 0 && !t.at.isBefore(from));
  final list = [
    for (final c in Category.spending) (category: c, spent: txns.where((t) => t.category == c).fold(0, (s, t) => s - t.cents)),
  ]..removeWhere((e) => e.spent == 0);
  list.sort((a, b) => b.spent.compareTo(a.spent));
  return list;
});

/// What a card has spent this week, against its limit.
final cardSpentProvider = Provider.family<int, String>((ref, id) {
  final from = dateOnly(ref.watch(clockProvider)()).subtract(const Duration(days: 6));
  return ref.watch(txnsProvider).where((t) => t.cardId == id && t.cents < 0 && !t.at.isBefore(from)).fold(0, (s, t) => s - t.cents);
});

// ------------------------------------------------------------ settings

class DemoSettings {
  const DemoSettings({this.theme = ThemeMode.system});

  final ThemeMode theme;
}

final demoSettingsProvider = NotifierProvider<DemoSettingsNotifier, DemoSettings>(DemoSettingsNotifier.new);

class DemoSettingsNotifier extends Notifier<DemoSettings> {
  static const _theme = 'tally.theme.v1';

  @override
  DemoSettings build() =>
      DemoSettings(theme: ThemeMode.values.asNameMap()[ref.read(prefsProvider).getString(_theme)] ?? ThemeMode.system);

  Future<void> setTheme(ThemeMode mode) async {
    state = DemoSettings(theme: mode);
    await ref.read(prefsProvider).setString(_theme, mode.name);
  }
}

Future<void> resetDemo(WidgetRef ref) async {
  await ref.read(prefsProvider).clear();
  ref.invalidate(cardsProvider);
  ref.invalidate(txnsProvider);
  ref.invalidate(frontCardProvider);
  ref.invalidate(demoSettingsProvider);
}
