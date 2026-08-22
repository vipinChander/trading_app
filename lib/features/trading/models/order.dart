import '../../../core/utils/money.dart';
import 'order_side.dart';

/// A completed (simulated) order. Orders are immutable once created --
/// there is no "edit order" concept, only new orders.
class Order {
  const Order({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.priceAtExecution,
    required this.totalValue,
    required this.executedAt,
  });

  final String id;
  final String symbol;
  final OrderSide side;
  final int quantity;

  /// LTP at the moment the order was submitted -- the price the
  /// simulated execution used.
  final Money priceAtExecution;

  /// `quantity * priceAtExecution`, computed once at execution time.
  final Money totalValue;

  final DateTime executedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'side': side.toJson(),
        'quantity': quantity,
        'priceAtExecution': priceAtExecution.toJson(),
        'totalValue': totalValue.toJson(),
        'executedAt': executedAt.toIso8601String(),
      };

  factory Order.fromJson(Map<dynamic, dynamic> json) {
    return Order(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      side: OrderSide.fromJson(json['side'] as String),
      quantity: json['quantity'] as int,
      priceAtExecution: Money.fromJson(json['priceAtExecution']),
      totalValue: Money.fromJson(json['totalValue']),
      executedAt: DateTime.parse(json['executedAt'] as String),
    );
  }
}
