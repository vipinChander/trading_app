import '../utils/money.dart';

/// Static metadata for one of the 10 tradable stocks.
class StockInfo {
  const StockInfo({
    required this.symbol,
    required this.name,
    required this.startingPrice,
  });

  final String symbol;
  final String name;

  /// The session's opening reference price. The mock feed uses this both
  /// as the initial LTP and as the fixed "previous close" reference that
  /// change/change% are computed against for the lifetime of the app run.
  final Money startingPrice;
}

/// The fixed universe of 10 stocks used throughout the app, per the
/// assignment spec. Prices are plausible starting points, not live data.
class StockCatalog {
  StockCatalog._();

  static const List<StockInfo> all = [
    StockInfo(symbol: 'RELIANCE', name: 'Reliance Industries', startingPrice: Money.fromPaise(245675)),
    StockInfo(symbol: 'TCS', name: 'Tata Consultancy Services', startingPrice: Money.fromPaise(389040)),
    StockInfo(symbol: 'INFY', name: 'Infosys', startingPrice: Money.fromPaise(151220)),
    StockInfo(symbol: 'HDFCBANK', name: 'HDFC Bank', startingPrice: Money.fromPaise(167890)),
    StockInfo(symbol: 'ICICIBANK', name: 'ICICI Bank', startingPrice: Money.fromPaise(114555)),
    StockInfo(symbol: 'SBIN', name: 'State Bank of India', startingPrice: Money.fromPaise(81230)),
    StockInfo(symbol: 'ITC', name: 'ITC Limited', startingPrice: Money.fromPaise(46215)),
    StockInfo(symbol: 'LT', name: 'Larsen & Toubro', startingPrice: Money.fromPaise(354000)),
    StockInfo(symbol: 'BHARTIARTL', name: 'Bharti Airtel', startingPrice: Money.fromPaise(129860)),
    StockInfo(symbol: 'AXISBANK', name: 'Axis Bank', startingPrice: Money.fromPaise(115675)),
  ];

  static final Map<String, StockInfo> _bySymbol = {
    for (final s in all) s.symbol: s,
  };

  static StockInfo byId(String symbol) {
    final info = _bySymbol[symbol];
    if (info == null) {
      throw ArgumentError('Unknown stock symbol: $symbol');
    }
    return info;
  }

  static bool isValidSymbol(String symbol) => _bySymbol.containsKey(symbol);

  static List<String> get allSymbols => all.map((s) => s.symbol).toList(growable: false);
}
