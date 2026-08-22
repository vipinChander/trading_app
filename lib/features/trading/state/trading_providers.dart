import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/persistence/app_database.dart';
import '../../../core/utils/money.dart';
import '../data/trading_repository.dart';
import '../models/holding.dart';
import '../models/order.dart';

final tradingRepositoryProvider = Provider<TradingRepository>((ref) {
  return TradingRepository(Hive.box(AppDatabase.boxName));
});

final walletControllerProvider = StateNotifierProvider<WalletController, Money>((ref) {
  return WalletController(ref.read(tradingRepositoryProvider));
});

final holdingsControllerProvider = StateNotifierProvider<HoldingsController, List<Holding>>((ref) {
  return HoldingsController(ref.read(tradingRepositoryProvider));
});

final orderHistoryControllerProvider = StateNotifierProvider<OrderHistoryController, List<Order>>((ref) {
  return OrderHistoryController(ref.read(tradingRepositoryProvider));
});

/// The wallet/margin balance available for buys. Debited on Buy, credited
/// on Sell, always kept in sync with Hive.
class WalletController extends StateNotifier<Money> {
  WalletController(this._repository) : super(_repository.readWalletBalance());

  final TradingRepository _repository;

  void debit(Money amount) {
    state = state - amount;
    _repository.saveWalletBalance(state);
  }

  void credit(Money amount) {
    state = state + amount;
    _repository.saveWalletBalance(state);
  }
}

/// Canonical positions. Only ever mutated by [applyBuy]/[applySell] --
/// price ticks never touch this state, they only feed the *display* of
/// derived P&L in the UI layer.
class HoldingsController extends StateNotifier<List<Holding>> {
  HoldingsController(this._repository) : super(_repository.readHoldings());

  final TradingRepository _repository;

  void _persist() => _repository.saveHoldings(state);

  Holding? byId(String symbol) {
    for (final h in state) {
      if (h.symbol == symbol) return h;
    }
    return null;
  }

  /// Adds shares, recomputing the weighted-average cost. Creates a new
  /// holding if one doesn't already exist for this symbol.
  void applyBuy(String symbol, int quantity, Money priceAtExecution) {
    final existing = byId(symbol);
    if (existing == null) {
      state = [...state, Holding(symbol: symbol, quantity: quantity, avgCost: priceAtExecution)];
    } else {
      final newQuantity = existing.quantity + quantity;
      final totalCostPaise = (existing.avgCost.paise * existing.quantity) +
          (priceAtExecution.paise * quantity);
      final newAvgCost = Money.fromPaise((totalCostPaise / newQuantity).round());
      state = [
        for (final h in state)
          if (h.symbol == symbol) h.copyWith(quantity: newQuantity, avgCost: newAvgCost) else h,
      ];
    }
    _persist();
  }

  /// Reduces shares held. If the resulting quantity is zero, the holding
  /// is removed entirely. Average cost is unchanged by a sell (standard
  /// practice -- only buys move the average).
  void applySell(String symbol, int quantity) {
    final existing = byId(symbol);
    if (existing == null) return;
    final remaining = existing.quantity - quantity;
    if (remaining <= 0) {
      state = state.where((h) => h.symbol != symbol).toList();
    } else {
      state = [
        for (final h in state)
          if (h.symbol == symbol) h.copyWith(quantity: remaining) else h,
      ];
    }
    _persist();
  }
}

/// Most-recent-first order history.
class OrderHistoryController extends StateNotifier<List<Order>> {
  OrderHistoryController(this._repository) : super(_repository.readOrders());

  final TradingRepository _repository;

  void add(Order order) {
    state = [order, ...state];
    _repository.saveOrders(state);
  }
}
