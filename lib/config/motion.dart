import 'package:flutter/widgets.dart';

/// How things move. How long the app *waits* is a different question and
/// lives in `AppTiming`.
abstract final class Motion {
  static const quick = Duration(milliseconds: 160);
  static const short = Duration(milliseconds: 240);
  static const medium = Duration(milliseconds: 380);
  static const long = Duration(milliseconds: 600);

  /// A screen's sections rising in, from one controller sliced by intervals.
  static const entrance = Duration(milliseconds: 1000);

  /// One screen handing over to the next.
  static const route = Duration(milliseconds: 620);

  /// A ring or bar filling to a new value.
  static const ring = Duration(milliseconds: 1100);

  /// A card turning over (front to back for the security code).
  static const flip = Duration(milliseconds: 640);

  /// The receipt feeding out of the printer, top to bottom.
  static const printing = Duration(milliseconds: 2600);

  /// Frost creeping across a frozen card, or melting off it.
  static const frost = Duration(milliseconds: 1200);

  static const shake = Duration(milliseconds: 520);

  /// A button breaking into fragments that fly together as its done state.
  static const morph = Duration(milliseconds: 900);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const settle = Curves.easeOutQuart;
  static const spring = Curves.easeOutBack;

  /// Ambient loops (the shine on cards, the printer's light, the backdrop)
  /// run only when this is true. Tests switch it off so `pumpAndSettle` can settle.
  static bool ambient = true;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static bool loops(BuildContext context) => ambient && !reduced(context);
}
