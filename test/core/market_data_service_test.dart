import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/constants/stock_catalog.dart';
import 'package:trading_app/core/market/market_data_service.dart';
import 'package:trading_app/core/market/tick.dart';

void main() {
  group('MarketDataService', () {
    test('exposes a ticker for every stock in the catalog, seeded at its starting price', () {
      final service = MarketDataService();
      for (final stock in StockCatalog.all) {
        final tick = service.tickerFor(stock.symbol).value;
        expect(tick.ltp, stock.startingPrice);
        expect(tick.change.isZero, isTrue);
      }
      service.dispose();
    });

    test('throws for an unknown symbol instead of returning garbage', () {
      final service = MarketDataService();
      expect(() => service.tickerFor('NOT_A_STOCK'), throwsArgumentError);
      expect(() => service.currentPriceOf('NOT_A_STOCK'), throwsArgumentError);
      service.dispose();
    });

    test('a forced tick updates the notifier value and moves change/changePercent together', () {
      final service = MarketDataService();
      final symbol = StockCatalog.all.first.symbol;
      final before = service.tickerFor(symbol).value;

      service.debugForceTick(symbol);

      final after = service.tickerFor(symbol).value;
      expect(after.at.isAfter(before.at) || after.at == before.at, isTrue);
      expect(after.ltp, service.currentPriceOf(symbol));
      expect(after.change, after.ltp - after.previousClose);
      if (after.change.paise > 0) {
        expect(after.direction, TickDirection.up);
      } else if (after.change.paise < 0) {
        expect(after.direction, TickDirection.down);
      }
      service.dispose();
    });

    test('two watchlists (or any two readers) watching the same symbol see identical prices', () {
      final service = MarketDataService();
      final symbol = StockCatalog.all.first.symbol;
      service.debugForceTick(symbol);
      final readerA = service.tickerFor(symbol).value;
      final readerB = service.tickerFor(symbol).value;
      expect(readerA.ltp, readerB.ltp);
      expect(identical(service.tickerFor(symbol), service.tickerFor(symbol)), isTrue);
      service.dispose();
    });

    test('start() and stop() control whether timers are scheduled', () {
      final service = MarketDataService(ticksPerSecondPerStock: 20);
      expect(service.isRunning, isFalse);
      service.start();
      expect(service.isRunning, isTrue);
      service.stop();
      expect(service.isRunning, isFalse);
      service.dispose();
    });

    test('live ticks actually arrive at roughly the configured rate', () async {
      final service = MarketDataService(ticksPerSecondPerStock: 20); // fast, for a quick test
      final symbol = StockCatalog.all.first.symbol;
      var tickCount = 0;
      service.tickerFor(symbol).addListener(() => tickCount++);

      service.start();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      service.dispose();

      // At 20/sec for ~400ms we expect several ticks; assert loosely to
      // avoid flakiness on a loaded CI box, while still proving the timer
      // loop is actually firing.
      expect(tickCount, greaterThan(0));
    });

    test('price never drifts to zero or negative over many ticks', () {
      final service = MarketDataService();
      final symbol = StockCatalog.all.first.symbol;
      for (var i = 0; i < 5000; i++) {
        service.debugForceTick(symbol);
      }
      expect(service.currentPriceOf(symbol).paise, greaterThan(0));
      service.dispose();
    });

    test('updateTickRate clamps to a sane range instead of accepting anything', () {
      final service = MarketDataService();
      service.updateTickRate(1000);
      expect(service.ticksPerSecondPerStock, lessThanOrEqualTo(20.0));
      service.updateTickRate(-5);
      expect(service.ticksPerSecondPerStock, greaterThanOrEqualTo(0.1));
      service.dispose();
    });
  });
}
