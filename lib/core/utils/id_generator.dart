import 'dart:math';

/// Generates short, unique-enough IDs for locally created entities
/// (watchlists, orders). We deliberately avoid pulling in the `uuid`
/// package for a handful of call sites -- this combines wall-clock
/// microseconds with a random suffix, which is more than sufficient
/// entropy for a single-user, single-device app.
class IdGenerator {
  IdGenerator._();

  static final Random _random = Random();

  static String next() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '$micros-$suffix';
  }
}
