import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/stock_catalog.dart';
import '../../../core/market/market_data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/flashing_tick_builder.dart';

/// One row inside a watchlist's detail screen: symbol, name, live LTP,
/// change, change% -- with drag handle + delete affordance supplied by
/// the caller (ReorderableListView / Dismissible), so this widget itself
/// stays focused purely on rendering the live price data for its symbol.
class WatchlistStockTile extends ConsumerWidget {
  const WatchlistStockTile({
    super.key,
    required this.symbol,
    required this.onTap,
    this.trailing,
  });

  final String symbol;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = StockCatalog.byId(symbol);
    final service = ref.watch(marketDataServiceProvider);

    return FlashingTickBuilder(
      ticker: service.tickerFor(symbol),
      builder: (context, tick, flashOverlay) {
        final color = MarketColors.forChange(tick.isUp, isFlat: tick.change.isZero);
        return Material(
          color: flashOverlay ?? Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(symbol, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          info.name,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      tick.ltp.format(),
                      textAlign: TextAlign.right,
                      style: priceTextStyle,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          tick.change.formatSigned(),
                          style: priceTextStyle.copyWith(color: color, fontSize: 12),
                        ),
                        Text(
                          formatPercent(tick.changePercent),
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
