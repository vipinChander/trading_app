import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../constants/stock_catalog.dart';
import '../utils/money.dart';
import 'tick.dart';

/// The single mock market-data feed for the entire app.
///
/// Design notes (why it looks the way it does):
///
/// * One [ValueNotifier<Tick>] per symbol. Every screen that needs a live
///   price for a symbol listens to *that specific notifier* (typically via
///   [ValueListenableBuilder] or [FlashingTickBuilder]). This means a tick
///   for RELIANCE only ever rebuilds widgets that are actually displaying
///   RELIANCE -- a Watchlist row, a Market Overview cell, a Holdings row,
///   and a Buy/Sell ticket can all be bound to the exact same notifier
///   simultaneously and will always agree, by construction. There is no
///   per-screen copy of price state to keep in sync.
///
/// * One [Timer] per symbol rather than a single global timer that fans
///   out to all ten. This makes the configured tick rate ("N ticks/sec
///   *per stock*") literal and lets each symbol's price walk evolve
///   independently, which is what a real feed looks like. Ten independent
///   periodic timers -- even at a stress-tested 5/sec each (50/sec total)
///   -- is trivial load for the Dart VM; the cost that actually matters is
///   how much *widget* work each tick triggers, which is why the
///   per-symbol ValueNotifier design above is the important part.
///
/// * The service is a plain Dart object (not tied to Flutter's widget
///   tree) so it can be unit tested directly and so it keeps running
///   uninterrupted regardless of which screen/tab is currently visible --
///   satisfying "when the user navigates away and returns, prices are
///   current, not stale".
class MarketDataService {
  MarketDataService({double ticksPerSecondPerStock = 1.0})
      : _ticksPerSecondPerStock = ticksPerSecondPerStock {
    for (final stock in StockCatalog.all) {
      _previousClose[stock.symbol] = stock.startingPrice;
      _currentPrice[stock.symbol] = stock.startingPrice;
      _notifiers[stock.symbol] = ValueNotifier<Tick>(
        Tick(
          symbol: stock.symbol,
          ltp: stock.startingPrice,
          previousClose: stock.startingPrice,
          change: Money.zero,
          changePercent: 0,
          direction: TickDirection.flat,
          at: DateTime.now(),
        ),
      );
    }
  }

  final Random _random = Random();
  final Map<String, Money> _previousClose = {};
  final Map<String, Money> _currentPrice = {};
  final Map<String, ValueNotifier<Tick>> _notifiers = {};
  final Map<String, Timer> _timers = {};

  double _ticksPerSecondPerStock;
  bool _running = false;
  bool _disposed = false;

  double get ticksPerSecondPerStock => _ticksPerSecondPerStock;
  bool get isRunning => _running;

  /// Read-only live handle for a symbol's price stream. Safe to call from
  /// any screen at any time -- returns the same notifier instance for the
  /// lifetime of the service.
  ValueListenable<Tick> tickerFor(String symbol) {
    final notifier = _notifiers[symbol];
    if (notifier == null) {
      throw ArgumentError('Unknown stock symbol: $symbol');
    }
    return notifier;
  }

  /// Snapshot of the current price without subscribing to updates. Useful
  /// for one-shot reads (e.g. "what price do I execute this order at").
  Money currentPriceOf(String symbol) {
    final price = _currentPrice[symbol];
    if (price == null) {
      throw ArgumentError('Unknown stock symbol: $symbol');
    }
    return price;
  }

  Tick latestTickOf(String symbol) => tickerFor(symbol).value;

  void start() {
    if (_running || _disposed) return;
    _running = true;
    for (final symbol in _notifiers.keys) {
      _scheduleSymbol(symbol);
    }
  }

  void stop() {
    _running = false;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Changes how many ticks/sec each of the 10 stocks emits. Reschedules
  /// all running timers immediately so the effect is visible right away --
  /// this is what backs the debug "tick rate" / stress-test control.
  void updateTickRate(double newTicksPerSecondPerStock) {
    _ticksPerSecondPerStock = newTicksPerSecondPerStock.clamp(0.1, 20.0).toDouble();
    if (!_running) return;
    for (final symbol in _notifiers.keys) {
      _scheduleSymbol(symbol);
    }
  }

  void _scheduleSymbol(String symbol) {
    _timers[symbol]?.cancel();
    final intervalMs = (1000 / _ticksPerSecondPerStock).round().clamp(50, 10000).toInt();
    // Stagger the first fire so 10 symbols starting at the same rate don't
    // all tick in lockstep on the same event-loop turn.
    final initialJitterMs = _random.nextInt(intervalMs);
    _timers[symbol] = Timer(Duration(milliseconds: initialJitterMs), () {
      _tick(symbol);
      _timers[symbol] = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _tick(symbol),
      );
    });
  }

  void _tick(String symbol) {
    if (_disposed) return;
    final current = _currentPrice[symbol]!;
    final previousClose = _previousClose[symbol]!;

    // A small, roughly symmetric random walk: +/-0.1% of the current
    // price per tick, with a slight mean-reversion pull back toward the
    // day's opening price so a session doesn't drift off to an absurd
    // level over thousands of ticks.
    final noise = (_random.nextDouble() - 0.5) * 0.002; // +/-0.1%
    final distanceFromOpen = (current.paise - previousClose.paise) / previousClose.paise;
    final meanReversion = -distanceFromOpen * 0.02;
    final pctMove = noise + meanReversion;

    var newPaise = current.paise + (current.paise * pctMove).round();

    // Keep prices within a sane band of the day's open so nothing walks
    // to zero (or to an unbounded value) over a long-running session.
    final floor = (previousClose.paise * 0.5).round();
    final ceiling = (previousClose.paise * 2.0).round();
    newPaise = newPaise.clamp(floor, ceiling).toInt();
    if (newPaise < 1) newPaise = 1;

    final newPrice = Money.fromPaise(newPaise);
    _currentPrice[symbol] = newPrice;

    final direction = newPaise > current.paise
        ? TickDirection.up
        : newPaise < current.paise
            ? TickDirection.down
            : TickDirection.flat;

    final change = newPrice - previousClose;

    _notifiers[symbol]!.value = Tick(
      symbol: symbol,
      ltp: newPrice,
      previousClose: previousClose,
      change: change,
      changePercent: percentChange(base: previousClose, current: newPrice),
      direction: direction,
      at: DateTime.now(),
    );
  }

  @visibleForTesting
  void debugForceTick(String symbol) => _tick(symbol);

  void dispose() {
    _disposed = true;
    stop();
    for (final notifier in _notifiers.values) {
      notifier.dispose();
    }
  }
}
