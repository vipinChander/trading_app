import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/market/market_data_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/holding.dart';
import '../models/order_side.dart';
import '../state/holdings_sort_mode.dart';
import '../state/trading_providers.dart';
import '../widgets/holding_row.dart';
import '../widgets/portfolio_summary_card.dart';
import 'buy_sell_ticket_screen.dart';
import 'order_history_screen.dart';

class HoldingsScreen extends ConsumerWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsControllerProvider);
    final sortMode = ref.watch(holdingsSortModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holdings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Order history',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            ),
          ),
          PopupMenuButton<HoldingsSortMode>(
            tooltip: 'Sort by',
            icon: const Icon(Icons.sort),
            initialValue: sortMode,
            onSelected: (mode) => ref.read(holdingsSortModeProvider.notifier).state = mode,
            itemBuilder: (_) => HoldingsSortMode.values
                .map((m) => PopupMenuItem(value: m, child: Text(m.label)))
                .toList(),
          ),
        ],
      ),
      body: holdings.isEmpty
          ? const EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'No holdings yet',
              message: 'Buy a stock from a watchlist or the Market tab to see it appear here.',
            )
          : Column(
              children: [
                const PortfolioSummaryCard(),
                Expanded(child: _SortedHoldingsList(holdings: holdings, sortMode: sortMode)),
              ],
            ),
    );
  }
}

/// Owns the *display order* of the holdings list. Every row still binds
/// directly to its own live price ticker (see [HoldingRow]) so P&L
/// numbers update every single tick without this widget rebuilding.
/// Sort order, however, is recomputed on a throttled ~500ms cadence
/// (immediately, too, whenever a buy/sell changes which holdings exist)
/// rather than on every tick -- resorting 10 rows 50 times a second would
/// add nothing a human could perceive, while recomputing it every ~500ms
/// keeps "a row crosses from loss to gain" visibly correct in well under
/// a second, without fighting the "smooth under load" requirement.
class _SortedHoldingsList extends ConsumerStatefulWidget {
  const _SortedHoldingsList({required this.holdings, required this.sortMode});

  final List<Holding> holdings;
  final HoldingsSortMode sortMode;

  @override
  ConsumerState<_SortedHoldingsList> createState() => _SortedHoldingsListState();
}

class _SortedHoldingsListState extends ConsumerState<_SortedHoldingsList> {
  late List<String> _order = _computeOrder(widget.holdings, widget.sortMode);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _maybeResort());
  }

  @override
  void didUpdateWidget(covariant _SortedHoldingsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final compositionChanged = !const SetEquality<String>().equals(
      oldWidget.holdings.map((h) => h.symbol).toSet(),
      widget.holdings.map((h) => h.symbol).toSet(),
    );
    if (compositionChanged || oldWidget.sortMode != widget.sortMode) {
      _order = _computeOrder(widget.holdings, widget.sortMode);
    }
  }

  void _maybeResort() {
    if (!mounted) return;
    final newOrder = _computeOrder(widget.holdings, widget.sortMode);
    if (!listEquals(newOrder, _order)) {
      setState(() => _order = newOrder);
    }
  }

  List<String> _computeOrder(List<Holding> holdings, HoldingsSortMode mode) {
    final service = ref.read(marketDataServiceProvider);
    final sorted = [...holdings];
    switch (mode) {
      case HoldingsSortMode.symbolAsc:
        sorted.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
      case HoldingsSortMode.valueDesc:
        sorted.sort((a, b) {
          final va = a.currentValue(service.currentPriceOf(a.symbol));
          final vb = b.currentValue(service.currentPriceOf(b.symbol));
          return vb.compareTo(va);
        });
        break;
      case HoldingsSortMode.pnlDesc:
        sorted.sort((a, b) {
          final pa = a.pnl(service.currentPriceOf(a.symbol));
          final pb = b.pnl(service.currentPriceOf(b.symbol));
          return pb.compareTo(pa);
        });
        break;
    }
    return sorted.map((h) => h.symbol).toList(growable: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _order.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final symbol = _order[index];
        final holding = widget.holdings.firstWhereOrNull((h) => h.symbol == symbol);
        if (holding == null) {
          // Removed by a concurrent sell; self-heals on the next resort.
          return const SizedBox.shrink();
        }
        return HoldingRow(
          key: ValueKey('holding-$symbol'),
          holding: holding,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BuySellTicketScreen(symbol: symbol, initialSide: OrderSide.sell),
            ),
          ),
        );
      },
    );
  }
}
