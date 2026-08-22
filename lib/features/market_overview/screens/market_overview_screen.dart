import 'package:flutter/material.dart';

import '../../../core/constants/stock_catalog.dart';
import '../widgets/market_row.dart';
import '../widgets/tick_rate_control_sheet.dart';

/// Feature 2: a continuously updating overview of all 10 stocks. Every
/// row is an independent [MarketRow] keyed by symbol, each bound to its
/// own slice of the single shared [MarketDataService] -- a tick for one
/// stock rebuilds exactly one row, never the [ListView] itself, which is
/// what keeps this screen smooth even at the stress-tested tick rate.
class MarketOverviewScreen extends StatelessWidget {
  const MarketOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Tick rate settings',
            onPressed: () => TickRateControlSheet.show(context),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: StockCatalog.all.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => MarketRow(
          key: ValueKey(StockCatalog.all[index].symbol),
          symbol: StockCatalog.all[index].symbol,
        ),
      ),
    );
  }
}
