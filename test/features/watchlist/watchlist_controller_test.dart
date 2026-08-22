import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trading_app/features/watchlist/data/watchlist_repository.dart';
import 'package:trading_app/features/watchlist/state/watchlist_controller.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late WatchlistController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('watchlist_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox('test_box_${DateTime.now().microsecondsSinceEpoch}');
    controller = WatchlistController(WatchlistRepository(box));
  });

  tearDown(() async {
    await box.close();
    await tempDir.delete(recursive: true);
  });

  test('starts empty', () {
    expect(controller.state, isEmpty);
  });

  test('create adds a watchlist with no stocks', () {
    final w = controller.create('Tech');
    expect(controller.state, hasLength(1));
    expect(w.name, 'Tech');
    expect(w.symbols, isEmpty);
  });

  test('addStock appends without duplicating', () {
    final w = controller.create('Tech');
    controller.addStock(w.id, 'TCS');
    controller.addStock(w.id, 'INFY');
    controller.addStock(w.id, 'TCS'); // duplicate, should be ignored

    expect(controller.byId(w.id)!.symbols, ['TCS', 'INFY']);
  });

  test('removeStock removes exactly the requested symbol', () {
    final w = controller.create('Tech');
    controller.addStock(w.id, 'TCS');
    controller.addStock(w.id, 'INFY');

    controller.removeStock(w.id, 'TCS');

    expect(controller.byId(w.id)!.symbols, ['INFY']);
  });

  test('reorderStock moves a symbol using ReorderableListView index semantics', () {
    final w = controller.create('Tech');
    controller.addStock(w.id, 'TCS');
    controller.addStock(w.id, 'INFY');
    controller.addStock(w.id, 'RELIANCE');

    // Move index 0 (TCS) to after index 2, as ReorderableListView reports it.
    controller.reorderStock(w.id, 0, 3);

    expect(controller.byId(w.id)!.symbols, ['INFY', 'RELIANCE', 'TCS']);
  });

  test('rename changes only the target watchlist', () {
    final a = controller.create('A');
    final b = controller.create('B');

    controller.rename(a.id, 'Renamed');

    expect(controller.byId(a.id)!.name, 'Renamed');
    expect(controller.byId(b.id)!.name, 'B');
  });

  test('delete removes the watchlist', () {
    final w = controller.create('Tech');
    controller.delete(w.id);
    expect(controller.state, isEmpty);
  });

  test('two watchlists can hold the same symbol independently', () {
    final a = controller.create('A');
    final b = controller.create('B');
    controller.addStock(a.id, 'TCS');
    controller.addStock(b.id, 'TCS');

    controller.removeStock(a.id, 'TCS');

    expect(controller.byId(a.id)!.symbols, isEmpty);
    expect(controller.byId(b.id)!.symbols, ['TCS']);
  });

  test('state survives being reloaded from the same underlying box (restart simulation)', () {
    final w = controller.create('Tech');
    controller.addStock(w.id, 'TCS');
    controller.addStock(w.id, 'INFY');
    controller.reorderStock(w.id, 0, 2);

    // Simulate an app restart: a brand new controller reading the same box.
    final restarted = WatchlistController(WatchlistRepository(box));

    expect(restarted.state, hasLength(1));
    expect(restarted.state.first.name, 'Tech');
    expect(restarted.state.first.symbols, ['INFY', 'TCS']);
  });
}
