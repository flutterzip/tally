/// Every deliberate wait in the app, in one place. A demo whose actions
/// finish in one frame reads as fake, and a loading state nobody sees can
/// not be judged.
///
/// `--dart-define=timingScale=0` skips every wait, the splash included, for
/// automation and screenshot runs.
abstract final class AppTiming {
  static double scale =
      double.tryParse(const String.fromEnvironment('timingScale')) ?? 1.0;

  // Splash phases.
  static Duration get splashIn => _s(2400);
  static Duration get splashHold => _s(400);
  static Duration get splashOut => _s(650);

  // Simulated network.
  static Duration get pay => _s(1100);
  static Duration get addCard => _s(1000);
  static Duration get freeze => _s(500);

  /// How long the done state holds before the next screen arrives: the
  /// button's particles fly together (`Motion.morph`), then a short look.
  static Duration get successBeat => _s(1250);

  static Duration _s(int ms) =>
      Duration(microseconds: (ms * 1000 * scale).round());

  static Future<void> wait(Duration d) =>
      d == Duration.zero ? Future.value() : Future.delayed(d);

  static Future<T> atLeast<T>(Duration d, Future<T> work) async {
    final results = await Future.wait<Object?>([work, wait(d)]);
    return results.first as T;
  }
}
