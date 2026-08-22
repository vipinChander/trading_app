import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/id_generator.dart';
import '../../../core/utils/money.dart';
import '../models/order.dart';
import '../models/order_side.dart';
import 'trading_providers.dart';

/// Outcome of a submitted order: either the created [Order], or a
/// human-readable reason it was rejected. Modeled as a small result type
/// rather than throwing, since "insufficient balance" / "not enough
/// shares" are expected, everyday outcomes -- not exceptional ones.
class OrderResult {
  const OrderResult._({this.order, this.errorMessage});

  factory OrderResult.success(Order order) => OrderResult._(order: order);
  factory OrderResult.failure(String message) => OrderResult._(errorMessage: message);

  final Order? order;
  final String? errorMessage;

  bool get isSuccess => order != null;
}

final tradingServiceProvider = Provider<TradingService>((ref) => TradingService(ref));

/// The one place order validation + execution happens. Both the Buy/Sell
/// ticket UI and any future caller go through this so the rules (margin
/// check, holding check, quantity sanity) can never be bypassed or
/// duplicated.
class TradingService {
  TradingService(this._ref);

  final Ref _ref;

  OrderResult submit({
    required String symbol,
    required OrderSide side,
    required int quantity,
    required Money ltpAtSubmission,
  }) {
    if (quantity <= 0) {
      return OrderResult.failure('Quantity must be a positive whole number of shares.');
    }

    final orderValue = ltpAtSubmission * quantity;
    final wallet = _ref.read(walletControllerProvider.notifier);
    final holdings = _ref.read(holdingsControllerProvider.notifier);

    if (side == OrderSide.buy) {
      final balance = _ref.read(walletControllerProvider);
      if (orderValue > balance) {
        return OrderResult.failure(
          'Insufficient balance. Available ${balance.format()}, order value ${orderValue.format()}.',
        );
      }
      wallet.debit(orderValue);
      holdings.applyBuy(symbol, quantity, ltpAtSubmission);
    } else {
      final held = holdings.byId(symbol)?.quantity ?? 0;
      if (quantity > held) {
        return OrderResult.failure('You only hold $held share${held == 1 ? '' : 's'} of $symbol.');
      }
      holdings.applySell(symbol, quantity);
      wallet.credit(orderValue);
    }

    final order = Order(
      id: IdGenerator.next(),
      symbol: symbol,
      side: side,
      quantity: quantity,
      priceAtExecution: ltpAtSubmission,
      totalValue: orderValue,
      executedAt: DateTime.now(),
    );
    _ref.read(orderHistoryControllerProvider.notifier).add(order);

    return OrderResult.success(order);
  }
}
