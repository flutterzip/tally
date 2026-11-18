import 'package:flutter/material.dart';

// ------------------------------------------------------------ money

/// Money is kept in whole cents, never in doubles.
///
/// `money(124826)` is `$1,248.26`; `money(-640, sign: true)` is `-$6.40`.
String money(int cents, {bool sign = false, bool whole = false}) {
  final neg = cents < 0;
  final abs = cents.abs();
  final dollars = abs ~/ 100;
  final digits = '$dollars';
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  final cents2 = (abs % 100).toString().padLeft(2, '0');
  final body = whole ? '\$$grouped' : '\$$grouped.$cents2';
  if (neg) return '-$body';
  return sign ? '+$body' : body;
}

/// What the keypad has typed, as cents: "12.5" is 1250.
int centsOf(String typed) {
  if (typed.isEmpty) return 0;
  final parts = typed.split('.');
  final whole = int.tryParse(parts[0].isEmpty ? '0' : parts[0]) ?? 0;
  final frac = parts.length > 1 ? parts[1].padRight(2, '0').substring(0, 2) : '00';
  return whole * 100 + int.parse(frac);
}

/// Adds a keypad key to what has been typed so far, or returns it
/// unchanged if the key is not allowed there (a second point, a third
/// decimal, more than 99,999 or a leading zero).
String pressKey(String typed, String key) {
  if (key == '<') return typed.isEmpty ? typed : typed.substring(0, typed.length - 1);
  if (key == '.') return typed.contains('.') ? typed : (typed.isEmpty ? '0.' : '$typed.');
  final dot = typed.indexOf('.');
  if (dot >= 0 && typed.length - dot > 2) return typed;
  if (dot < 0 && typed.length >= 5) return typed;
  if (typed == '0') return key == '0' ? typed : key;
  return '$typed$key';
}

// ------------------------------------------------------------ cards

class PayCard {
  const PayCard({
    required this.id,
    required this.name,
    required this.kind,
    required this.number,
    required this.expiry,
    required this.cvv,
    required this.tone,
    required this.limitCents,
    this.frozen = false,
  });

  final String id, name, kind, number, expiry, cvv;

  /// Which step of the accent the card is drawn in, 0 to 3.
  final int tone;
  final int limitCents;
  final bool frozen;

  String get last4 {
    final digits = number.replaceAll(' ', '');
    return digits.length < 4 ? digits : digits.substring(digits.length - 4);
  }

  PayCard copyWith({bool? frozen}) => PayCard(
        id: id,
        name: name,
        kind: kind,
        number: number,
        expiry: expiry,
        cvv: cvv,
        tone: tone,
        limitCents: limitCents,
        frozen: frozen ?? this.frozen,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'kind': kind,
        'number': number,
        'expiry': expiry,
        'cvv': cvv,
        'tone': tone,
        'limitCents': limitCents,
        'frozen': frozen,
      };

  factory PayCard.fromJson(Map<String, Object?> j) => PayCard(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: j['kind'] as String,
        number: j['number'] as String,
        expiry: j['expiry'] as String,
        cvv: j['cvv'] as String,
        tone: j['tone'] as int,
        limitCents: j['limitCents'] as int,
        frozen: j['frozen'] as bool? ?? false,
      );
}

/// Puts a space after every fourth digit, keeping at most 16.
String groupCardNumber(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  final cut = d.length > 16 ? d.substring(0, 16) : d;
  final b = StringBuffer();
  for (var i = 0; i < cut.length; i++) {
    if (i > 0 && i % 4 == 0) b.write(' ');
    b.write(cut[i]);
  }
  return b.toString();
}

/// MM/YY as you type: a slash after the month.
String formatExpiry(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  final cut = d.length > 4 ? d.substring(0, 4) : d;
  return cut.length <= 2 ? cut : '${cut.substring(0, 2)}/${cut.substring(2)}';
}

/// Whether a card number passes the Luhn check every real card number does.
bool luhn(String number) {
  final d = number.replaceAll(' ', '');
  if (d.length < 13) return false;
  var sum = 0;
  for (var i = 0; i < d.length; i++) {
    var n = int.parse(d[d.length - 1 - i]);
    if (i.isOdd) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
  }
  return sum % 10 == 0;
}

/// A month that has not passed yet, as MM/YY, on [today].
bool expiryValid(String mmyy, DateTime today) {
  final m = RegExp(r'^(\d\d)/(\d\d)$').firstMatch(mmyy);
  if (m == null) return false;
  final month = int.parse(m[1]!), year = 2000 + int.parse(m[2]!);
  if (month < 1 || month > 12) return false;
  return year > today.year || (year == today.year && month >= today.month);
}

// ------------------------------------------------------------ people

class Contact {
  const Contact({required this.id, required this.name, required this.handle, required this.tone});

  final String id, name, handle;
  final int tone;

  String get firstName => name.split(' ').first;

  String get initials => name.split(' ').map((w) => w[0]).take(2).join();

  factory Contact.fromJson(Map<String, Object?> j) =>
      Contact(id: j['id'] as String, name: j['name'] as String, handle: j['handle'] as String, tone: j['tone'] as int);
}

// ------------------------------------------------------------ activity

enum Category {
  food('Food', Icons.restaurant_rounded),
  transport('Transport', Icons.directions_transit_rounded),
  shopping('Shopping', Icons.shopping_bag_rounded),
  bills('Bills', Icons.receipt_long_rounded),
  fun('Going out', Icons.local_activity_rounded),
  transfer('Transfers', Icons.swap_horiz_rounded),
  income('Income', Icons.south_west_rounded);

  const Category(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Categories that count as spending.
  static const spending = [food, transport, shopping, bills, fun];
}

class Txn {
  const Txn({
    required this.id,
    required this.title,
    required this.category,
    required this.cents,
    required this.at,
    this.cardId,
    this.contactId,
    this.note,
  });

  final String id, title;
  final Category category;

  /// Negative when money goes out.
  final int cents;
  final DateTime at;
  final String? cardId, contactId, note;

  /// A short reference, as printed on the receipt.
  String get ref {
    var h = 7;
    for (final c in id.codeUnits) {
      h = (h * 31 + c) % 100000000;
    }
    return 'TL${h.toString().padLeft(8, '0')}';
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'cents': cents,
        'at': at.toIso8601String(),
        'card': cardId,
        'contact': contactId,
        'note': note,
      };

  factory Txn.fromJson(Map<String, Object?> j) => Txn(
        id: j['id'] as String,
        title: j['title'] as String,
        category: Category.values.byName(j['category'] as String),
        cents: j['cents'] as int,
        at: DateTime.parse(j['at'] as String),
        cardId: j['card'] as String?,
        contactId: j['contact'] as String?,
        note: j['note'] as String?,
      );
}

// ------------------------------------------------------------ dates

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String weekday(DateTime d) => _weekdays[d.weekday - 1];

/// "Today", "Yesterday" or "Mon 16 Nov".
String dayLabel(DateTime d, DateTime today) {
  final days = dateOnly(today).difference(dateOnly(d)).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  return '${weekday(d)} ${d.day} ${_months[d.month - 1]}';
}

/// "18 Nov 2026, 09:41".
String stamp(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "09:41".
String clock(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
