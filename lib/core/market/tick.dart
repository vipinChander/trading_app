import '../utils/money.dart';

/// Direction of the most recent price move, used purely to decide which
/// way a UI cell should flash (green up / red down). This is about the
/// *last tick's* movement, which is distinct from [Tick.change], which is
/// always measured against the fixed session-open reference price.
enum TickDirection { up, down, flat }

/// A single immutable price update for one stock. This is the only shape
/// of data the mock feed ever produces, and the only shape every screen
/// in the app (Watchlist, Market Overview, Buy/Sell ticket, Holdings)
/// ever reads -- there is exactly one source of truth for prices.
class Tick {
  const Tick({
    required this.symbol,
    required this.ltp,
    required this.previousClose,
    required this.change,
    required this.changePercent,
    required this.direction,
    required this.at,
  });

  final String symbol;

  /// Last traded price.
  final Money ltp;

  /// Fixed reference price the session opened at (does not change).
  final Money previousClose;

  /// `ltp - previousClose`.
  final Money change;

  /// `change` as a percentage of `previousClose`.
  final double changePercent;

  /// Whether this tick moved the price up, down, or left it unchanged
  /// relative to the previous tick.
  final TickDirection direction;

  final DateTime at;

  bool get isUp => change.paise >= 0;
}
