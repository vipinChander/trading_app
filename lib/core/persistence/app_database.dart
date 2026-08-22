import 'package:hive_flutter/hive_flutter.dart';

/// Thin wrapper around a single Hive box used for all app persistence.
///
/// We deliberately avoid Hive's generated `TypeAdapter`s (which need
/// `build_runner`, an extra codegen step) and instead store plain
/// `Map`/`List`/`String`/`int` values -- Hive supports these natively.
/// Every model in the app has a `toJson`/`fromJson` pair and the
/// repositories below just read/write those maps directly. This keeps the
/// project runnable with nothing beyond `flutter pub get && flutter run`.
class AppDatabase {
  AppDatabase._();

  static const String boxName = 'trading_app_box';

  static Box? _box;

  static bool get isReady => _box != null;

  static Box get box {
    final box = _box;
    if (box == null) {
      throw StateError(
        'AppDatabase.init() must complete before the box is used.',
      );
    }
    return box;
  }

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(boxName);
  }
}

/// Keys for the top-level blobs stored in the single app box. Each feature
/// owns one key and stores its entire collection as a JSON-friendly
/// list/primitive under it -- simple, and plenty for this app's scale
/// (10 stocks, a handful of watchlists, a bounded order history).
class HiveKeys {
  HiveKeys._();

  static const watchlists = 'watchlists_v1';
  static const walletBalancePaise = 'wallet_balance_paise_v1';
  static const holdings = 'holdings_v1';
  static const orders = 'orders_v1';
}
