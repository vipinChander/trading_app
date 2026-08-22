import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trading_app/core/constants/stock_catalog.dart';
import 'package:trading_app/core/utils/money.dart';
import 'package:trading_app/features/trading/data/trading_repository.dart';
import 'package:trading_app/features/trading/models/order_side.dart';
import 'package:trading_app/features/trading/state/trading_providers.dart';
import 'package:trading_app/features/trading/state/trading_service.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('trading_app_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox('test_box_${DateTime.now().microsecondsSinceEpoch}');
    container = ProviderContainer(
      overrides: [
        tradingRepositoryProvider.overrideWithValue(TradingRepository(box)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await box.close();
    await tempDir.delete(recursive: true);
  });

  const symbol = 'RELIANCE';
  final ltp = StockCatalog.byId(symbol).startingPrice;

  group('TradingService.submit', () {
    test('rejects zero and negative quantities', () {
      final service = container.read(tradingServiceProvider);
      expect(
        service.submit(symbol: symbol, side: OrderSide.buy, quantity: 0, ltpAtSubmission: ltp).isSuccess,
        isFalse,
      );
      expect(
        service.submit(symbol: symbol, side: OrderSide.buy, quantity: -3, ltpAtSubmission: ltp).isSuccess,
        isFalse,
      );
    });

    test('a successful buy debits the wallet by exactly qty * ltp and creates a holding', () {
      final service = container.read(tradingServiceProvider);
      final startingBalance = container.read(walletControllerProvider);

      final result = service.submit(symbol: symbol, side: OrderSide.buy, quantity: 10, ltpAtSubmission: ltp);

      expect(result.isSuccess, isTrue);
      expect(container.read(walletControllerProvider), startingBalance - (ltp * 10));

      final holding = container.read(holdingsControllerProvider.notifier).byId(symbol);
      expect(holding, isNotNull);
      expect(holding!.quantity, 10);
      expect(holding.avgCost, ltp);

      final orders = container.read(orderHistoryControllerProvider);
      expect(orders, hasLength(1));
      expect(orders.first.totalValue, ltp * 10);
    });

    test('a second buy at a different price recomputes a correct weighted average cost', () {
      final service = container.read(tradingServiceProvider);
      service.submit(symbol: symbol, side: OrderSide.buy, quantity: 10, ltpAtSubmission: Money.fromRupees(100));
      service.submit(symbol: symbol, side: OrderSide.buy, quantity: 10, ltpAtSubmission: Money.fromRupees(200));

      final holding = container.read(holdingsControllerProvider.notifier).byId(symbol);
      expect(holding!.quantity, 20);
      // (10*100 + 10*200) / 20 = 150
      expect(holding.avgCost, Money.fromRupees(150));
    });

    test('buy is blocked when order value exceeds available balance', () {
      final service = container.read(tradingServiceProvider);
      final balance = container.read(walletControllerProvider);
      // A quantity guaranteed to exceed the wallet at this price.
      final tooMany = (balance.paise ~/ ltp.paise) + 1000;

      final result = service.submit(symbol: symbol, side: OrderSide.buy, quantity: tooMany, ltpAtSubmission: ltp);

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Insufficient balance'));
      expect(container.read(walletControllerProvider), balance, reason: 'balance must be unchanged on a rejected order');
      expect(container.read(holdingsControllerProvider), isEmpty);
    });

    test('sell is blocked when quantity exceeds what is held', () {
      final service = container.read(tradingServiceProvider);
      service.submit(symbol: symbol, side: OrderSide.buy, quantity: 5, ltpAtSubmission: ltp);

      final result = service.submit(symbol: symbol, side: OrderSide.sell, quantity: 6, ltpAtSubmission: ltp);

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('only hold'));
      expect(container.read(holdingsControllerProvider.notifier).byId(symbol)!.quantity, 5);
    });

    test('selling everything removes the holding entirely and credits the wallet', () {
      final service = container.read(tradingServiceProvider);
      service.submit(symbol: symbol, side: OrderSide.buy, quantity: 8, ltpAtSubmission: ltp);
      final balanceAfterBuy = container.read(walletControllerProvider);

      final result = service.submit(symbol: symbol, side: OrderSide.sell, quantity: 8, ltpAtSubmission: ltp);

      expect(result.isSuccess, isTrue);
      expect(container.read(holdingsControllerProvider.notifier).byId(symbol), isNull);
      expect(container.read(walletControllerProvider), balanceAfterBuy + (ltp * 8));
    });

    test('partial sell reduces quantity without changing average cost', () {
      final service = container.read(tradingServiceProvider);
      service.submit(symbol: symbol, side: OrderSide.buy, quantity: 10, ltpAtSubmission: Money.fromRupees(100));

      service.submit(symbol: symbol, side: OrderSide.sell, quantity: 4, ltpAtSubmission: Money.fromRupees(150));

      final holding = container.read(holdingsControllerProvider.notifier).byId(symbol);
      expect(holding!.quantity, 6);
      expect(holding.avgCost, Money.fromRupees(100));
    });

    test('order history is most-recent-first', () {
      final service = container.read(tradingServiceProvider);
      service.submit(symbol: symbol, side: OrderSide.buy, quantity: 1, ltpAtSubmission: ltp);
      service.submit(symbol: symbol, side: OrderSide.buy, quantity: 2, ltpAtSubmission: ltp);

      final orders = container.read(orderHistoryControllerProvider);
      expect(orders.first.quantity, 2);
      expect(orders.last.quantity, 1);
    });
  });
}
