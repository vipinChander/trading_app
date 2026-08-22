import '../../../core/utils/money.dart';

/// A current position in one stock. Only mutated by buys/sells -- never
/// touched directly by price ticks. Live figures (current value, P&L)
/// are always *derived* on the fly from this plus the latest LTP, never
/// stored, so they can never go stale relative to the feed.
class Holding {
  const Holding({
    required this.symbol,
    required this.quantity,
    required this.avgCost,
  });

  final String symbol;
  final int quantity;

  /// Weighted average cost per share across all buys.
  final Money avgCost;

  Money get investedValue => avgCost * quantity;

  Money currentValue(Money ltp) => ltp * quantity;

  Money pnl(Money ltp) => currentValue(ltp) - investedValue;

  double pnlPercent(Money ltp) {
    if (investedValue.paise == 0) return 0;
    return (pnl(ltp).paise / investedValue.paise) * 100;
  }

  Holding copyWith({int? quantity, Money? avgCost}) {
    return Holding(
      symbol: symbol,
      quantity: quantity ?? this.quantity,
      avgCost: avgCost ?? this.avgCost,
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'quantity': quantity,
        'avgCost': avgCost.toJson(),
      };

  factory Holding.fromJson(Map<dynamic, dynamic> json) {
    return Holding(
      symbol: json['symbol'] as String,
      quantity: json['quantity'] as int,
      avgCost: Money.fromJson(json['avgCost']),
    );
  }
}
