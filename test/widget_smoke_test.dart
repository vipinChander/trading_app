import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trading_app/app.dart';
import 'package:trading_app/core/market/market_data_providers.dart';
import 'package:trading_app/core/market/market_data_service.dart';
import 'package:trading_app/core/persistence/app_database.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('widget_smoke_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppDatabase.boxName);
  });

  tearDownAll(() async {
    await Hive.box(AppDatabase.boxName).close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('app boots to an empty Watchlists tab and can switch tabs', (tester) async {
    // A market data service that is never started: no timers, so the
    // widget test binding never sees a "pending timer" at teardown, while
    // every ticker still holds its seeded starting-price value.
    final service = MarketDataService();
    addTearDown(service.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [marketDataServiceProvider.overrideWithValue(service)],
        child: const TradingApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Watchlists'), findsWidgets);
    expect(find.text('No watchlists yet'), findsOneWidget);

    await tester.tap(find.text('Market'));
    await tester.pumpAndSettle();
    expect(find.text('RELIANCE'), findsOneWidget);

    await tester.tap(find.text('Holdings'));
    await tester.pumpAndSettle();
    expect(find.text('No holdings yet'), findsOneWidget);
  });

  testWidgets('creating a watchlist and opening it shows the empty-watchlist state', (tester) async {
    final service = MarketDataService();
    addTearDown(service.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [marketDataServiceProvider.overrideWithValue(service)],
        child: const TradingApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create watchlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My List');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('My List'), findsWidgets);
    expect(find.text('This watchlist is empty'), findsOneWidget);
  });
}
