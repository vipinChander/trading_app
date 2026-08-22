import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/stock_catalog.dart';
import '../../../core/market/market_data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/flashing_tick_builder.dart';
import '../../trading/screens/buy_sell_ticket_screen.dart';

/// A single row of the Live Prices Mimic screen: symbol, LTP, change,
/// change%, and a brief green/red flash on every tick. This is the
/// highest-frequency widget in the app (up to 5 rebuilds/sec/row at the
/// stress-test rate), so it's kept deliberately shallow -- no extra
/// Consumer layers beyond reading the feed once for the ticker handle.
class MarketRow extends ConsumerWidget {
  const MarketRow({super.key, required this.symbol});

  final String symbol;

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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BuySellTicketScreen(symbol: symbol)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(symbol, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(info.name, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(tick.ltp.format(), textAlign: TextAlign.right, style: priceTextStyle),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(tick.change.formatSigned(), style: priceTextStyle.copyWith(color: color, fontSize: 12)),
                        Text(formatPercent(tick.changePercent), style: TextStyle(color: color, fontSize: 12)),
                      ],
                    ),
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
