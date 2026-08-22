import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/stock_catalog.dart';
import '../../../core/market/market_data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/flashing_tick_builder.dart';
import '../models/holding.dart';

/// One Holdings row. Subscribes to its own symbol's live ticks directly
/// (via [FlashingTickBuilder]) so a tick for this stock re-renders only
/// this row -- the parent list is never rebuilt for a price update, only
/// for a change in *which* holdings exist or their static qty/avg cost.
class HoldingRow extends ConsumerWidget {
  const HoldingRow({super.key, required this.holding, required this.onTap});

  final Holding holding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = StockCatalog.byId(holding.symbol);
    final service = ref.watch(marketDataServiceProvider);

    return FlashingTickBuilder(
      ticker: service.tickerFor(holding.symbol),
      builder: (context, tick, flashOverlay) {
        final pnl = holding.pnl(tick.ltp);
        final pnlPercent = holding.pnlPercent(tick.ltp);
        final color = MarketColors.forChange(pnl.paise >= 0, isFlat: pnl.isZero);

        return Material(
          color: flashOverlay ?? Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(holding.symbol, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              '${formatQuantity(holding.quantity)} sh @ ${holding.avgCost.format()}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(tick.ltp.format(), style: priceTextStyle),
                          Text(
                            holding.currentValue(tick.ltp).format(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(info.name, style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        '${pnl.formatSigned()} (${formatPercent(pnlPercent)})',
                        style: TextStyle(color: color, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
