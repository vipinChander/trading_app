import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/persistence/app_database.dart';
import '../data/watchlist_repository.dart';
import '../models/watchlist.dart';
import '../../../core/utils/id_generator.dart';

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return WatchlistRepository(Hive.box(AppDatabase.boxName));
});

final watchlistControllerProvider =
    StateNotifierProvider<WatchlistController, List<Watchlist>>((ref) {
  return WatchlistController(ref.read(watchlistRepositoryProvider));
});

/// Owns the canonical, persisted list of watchlists. Every mutation is
/// synchronous against in-memory state (so the UI updates instantly) and
/// then fire-and-forget persisted to Hive.
class WatchlistController extends StateNotifier<List<Watchlist>> {
  WatchlistController(this._repository) : super(_repository.readAll());

  final WatchlistRepository _repository;

  void _persist() => _repository.saveAll(state);

  Watchlist create(String name) {
    final watchlist = Watchlist(id: IdGenerator.next(), name: name.trim(), symbols: const []);
    state = [...state, watchlist];
    _persist();
    return watchlist;
  }

  void rename(String watchlistId, String newName) {
    state = [
      for (final w in state)
        if (w.id == watchlistId) w.copyWith(name: newName.trim()) else w,
    ];
    _persist();
  }

  void delete(String watchlistId) {
    state = state.where((w) => w.id != watchlistId).toList();
    _persist();
  }

  Watchlist? byId(String watchlistId) {
    for (final w in state) {
      if (w.id == watchlistId) return w;
    }
    return null;
  }

  void addStock(String watchlistId, String symbol) {
    state = [
      for (final w in state)
        if (w.id == watchlistId && !w.symbols.contains(symbol))
          w.copyWith(symbols: [...w.symbols, symbol])
        else
          w,
    ];
    _persist();
  }

  void removeStock(String watchlistId, String symbol) {
    state = [
      for (final w in state)
        if (w.id == watchlistId)
          w.copyWith(symbols: w.symbols.where((s) => s != symbol).toList())
        else
          w,
    ];
    _persist();
  }

  /// Moves the symbol at [oldIndex] to [newIndex], following the same
  /// index convention Flutter's [ReorderableListView] uses (the caller
  /// passes the raw `onReorder` indices straight through).
  void reorderStock(String watchlistId, int oldIndex, int newIndex) {
    state = [
      for (final w in state)
        if (w.id == watchlistId) w.copyWith(symbols: _moved(w.symbols, oldIndex, newIndex)) else w,
    ];
    _persist();
  }

  List<String> _moved(List<String> symbols, int oldIndex, int newIndex) {
    final list = [...symbols];
    var target = newIndex;
    if (oldIndex < target) target -= 1;
    final symbol = list.removeAt(oldIndex);
    list.insert(target, symbol);
    return list;
  }
}
