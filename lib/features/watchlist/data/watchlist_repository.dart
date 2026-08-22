import 'package:hive/hive.dart';

import '../../../core/persistence/app_database.dart';
import '../models/watchlist.dart';

/// Reads/writes the full set of watchlists as one JSON-friendly blob.
///
/// Kept intentionally simple (whole-collection read/write rather than
/// per-row persistence) -- this app's data scale (a handful of
/// watchlists, 10 possible stocks each) makes that the right tradeoff:
/// one clear read path, one clear write path, no partial-write states to
/// reason about.
class WatchlistRepository {
  WatchlistRepository(this._box);

  final Box _box;

  List<Watchlist> readAll() {
    final raw = _box.get(HiveKeys.watchlists, defaultValue: const <dynamic>[]) as List;
    return raw
        .map((e) => Watchlist.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  Future<void> saveAll(List<Watchlist> watchlists) {
    return _box.put(
      HiveKeys.watchlists,
      watchlists.map((w) => w.toJson()).toList(growable: false),
    );
  }
}
