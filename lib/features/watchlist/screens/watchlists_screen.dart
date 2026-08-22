import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../state/watchlist_controller.dart';
import '../widgets/watchlist_name_dialog.dart';
import 'watchlist_detail_screen.dart';

class WatchlistsScreen extends ConsumerWidget {
  const WatchlistsScreen({super.key});

  Future<void> _createWatchlist(BuildContext context, WidgetRef ref) async {
    final name = await WatchlistNameDialog.show(
      context,
      title: 'New watchlist',
      confirmLabel: 'Create',
    );
    if (name == null || name.isEmpty) return;
    final watchlist = ref.read(watchlistControllerProvider.notifier).create(name);
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WatchlistDetailScreen(watchlistId: watchlist.id)),
      );
    }
  }

  Future<void> _renameWatchlist(BuildContext context, WidgetRef ref, String id, String current) async {
    final name = await WatchlistNameDialog.show(
      context,
      title: 'Rename watchlist',
      confirmLabel: 'Save',
      initialValue: current,
    );
    if (name == null || name.isEmpty) return;
    ref.read(watchlistControllerProvider.notifier).rename(id, name);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete watchlist?'),
        content: Text('"$name" and its stocks will be removed. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(watchlistControllerProvider.notifier).delete(id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlists = ref.watch(watchlistControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlists')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createWatchlist(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New watchlist'),
      ),
      body: watchlists.isEmpty
          ? EmptyState(
              icon: Icons.visibility_outlined,
              title: 'No watchlists yet',
              message: 'Create a watchlist to start tracking stocks you care about.',
              actionLabel: 'Create watchlist',
              onAction: () => _createWatchlist(context, ref),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: watchlists.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final w = watchlists[index];
                return ListTile(
                  title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    w.symbols.isEmpty ? 'No stocks yet' : w.symbols.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'rename') _renameWatchlist(context, ref, w.id, w.name);
                      if (action == 'delete') _confirmDelete(context, ref, w.id, w.name);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => WatchlistDetailScreen(watchlistId: w.id)),
                  ),
                );
              },
            ),
    );
  }
}
