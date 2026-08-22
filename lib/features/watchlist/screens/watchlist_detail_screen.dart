import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../trading/screens/buy_sell_ticket_screen.dart';
import '../state/watchlist_controller.dart';
import '../widgets/stock_picker_sheet.dart';
import '../widgets/watchlist_name_dialog.dart';
import '../widgets/watchlist_stock_tile.dart';

class WatchlistDetailScreen extends ConsumerWidget {
  const WatchlistDetailScreen({super.key, required this.watchlistId});

  final String watchlistId;

  Future<void> _addStock(BuildContext context, WidgetRef ref, Set<String> existing) async {
    final symbol = await StockPickerSheet.show(context, alreadyAdded: existing);
    if (symbol != null) {
      ref.read(watchlistControllerProvider.notifier).addStock(watchlistId, symbol);
    }
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, String current) async {
    final name = await WatchlistNameDialog.show(
      context,
      title: 'Rename watchlist',
      confirmLabel: 'Save',
      initialValue: current,
    );
    if (name != null && name.isNotEmpty) {
      ref.read(watchlistControllerProvider.notifier).rename(watchlistId, name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlists = ref.watch(watchlistControllerProvider);
    final watchlist = watchlists.where((w) => w.id == watchlistId).firstOrNull;

    if (watchlist == null) {
      // The watchlist was deleted (e.g. from the list screen) while this
      // detail screen was still on the stack. Fail gracefully instead of
      // crashing on a null lookup.
      return Scaffold(
        appBar: AppBar(title: const Text('Watchlist')),
        body: const EmptyState(
          icon: Icons.info_outline,
          title: 'This watchlist was deleted',
          message: 'Go back to see your remaining watchlists.',
        ),
      );
    }

    final symbols = watchlist.symbols;

    return Scaffold(
      appBar: AppBar(
        title: Text(watchlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Rename',
            onPressed: () => _rename(context, ref, watchlist.name),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addStock(context, ref, symbols.toSet()),
        child: const Icon(Icons.add),
      ),
      body: symbols.isEmpty
          ? EmptyState(
              icon: Icons.playlist_add_outlined,
              title: 'This watchlist is empty',
              message: 'Add stocks to start tracking their live prices here.',
              actionLabel: 'Add a stock',
              onAction: () => _addStock(context, ref, symbols.toSet()),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: symbols.length,
              onReorder: (oldIndex, newIndex) {
                ref.read(watchlistControllerProvider.notifier).reorderStock(watchlistId, oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final symbol = symbols[index];
                return Dismissible(
                  key: ValueKey('watchlist-$watchlistId-$symbol'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete_outline),
                  ),
                  onDismissed: (_) {
                    ref.read(watchlistControllerProvider.notifier).removeStock(watchlistId, symbol);
                  },
                  child: WatchlistStockTile(
                    key: ValueKey('tile-$symbol'),
                    symbol: symbol,
                    trailing: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.drag_handle, size: 20),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BuySellTicketScreen(symbol: symbol)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
