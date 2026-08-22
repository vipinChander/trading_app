import 'package:hive/hive.dart';

import '../../../core/persistence/app_database.dart';
import '../../../core/utils/money.dart';
import '../models/holding.dart';
import '../models/order.dart';

/// Starting virtual balance for a fresh install. Chosen to comfortably
/// cover a handful of round-lot trades across the 10 stocks without the
/// wallet feeling infinite.
final Money kStartingWalletBalance = Money.fromRupees(500000);

/// Persists the three pieces of state the trading engine owns: wallet
/// balance, current holdings, and order history. Grouped in one
/// repository (backed by the same shared Hive box as everything else)
/// because they are always mutated together as part of a single "submit
/// order" transaction -- see [TradingService].
class TradingRepository {
  TradingRepository(this._box);

  final Box _box;

  Money readWalletBalance() {
    final raw = _box.get(HiveKeys.walletBalancePaise);
    if (raw == null) return kStartingWalletBalance;
    return Money.fromPaise(raw as int);
  }

  Future<void> saveWalletBalance(Money balance) {
    return _box.put(HiveKeys.walletBalancePaise, balance.paise);
  }

  List<Holding> readHoldings() {
    final raw = _box.get(HiveKeys.holdings, defaultValue: const <dynamic>[]) as List;
    return raw
        .map((e) => Holding.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  Future<void> saveHoldings(List<Holding> holdings) {
    return _box.put(HiveKeys.holdings, holdings.map((h) => h.toJson()).toList(growable: false));
  }

  /// Most-recent-first order history.
  List<Order> readOrders() {
    final raw = _box.get(HiveKeys.orders, defaultValue: const <dynamic>[]) as List;
    return raw
        .map((e) => Order.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  Future<void> saveOrders(List<Order> orders) {
    return _box.put(HiveKeys.orders, orders.map((o) => o.toJson()).toList(growable: false));
  }
}
