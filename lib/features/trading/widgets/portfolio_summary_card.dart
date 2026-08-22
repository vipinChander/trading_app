import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/market/market_data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../state/trading_providers.dart';

/// Aggregate P&L across every holding.
///
/// Rebuilds on every tick of every held symbol (via
/// `Listenable.merge`) -- but that's the *only* thing this small card
/// does, so recomputing a sum over at most 10 holdings on each tick is
/// cheap even at a stress-tested 50 ticks/sec. It never touches, and
/// never triggers a rebuild of, the holdings list below it.
class PortfolioSummaryCard extends ConsumerWidget {
  const PortfolioSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsControllerProvider);
    final service = ref.watch(marketDataServiceProvider);
    final tickers = holdings.map((h) => service.tickerFor(h.symbol)).toList(growable: false);

    return AnimatedBuilder(
      animation: Listenable.merge(tickers),
      builder: (context, _) {
        Money invested = Money.zero;
        Money current = Money.zero;
        for (final h in holdings) {
          final ltp = service.currentPriceOf(h.symbol);
          invested = invested + h.investedValue;
          current = current + h.currentValue(ltp);
        }
        final pnl = current - invested;
        final pnlPercent = invested.isZero ? 0.0 : (pnl.paise / invested.paise) * 100;
        final color = MarketColors.forChange(pnl.paise >= 0, isFlat: pnl.isZero);

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Portfolio summary', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _stat(context, 'Invested', invested.format()),
                    _stat(context, 'Current value', current.format()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total P&L', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${pnl.formatSigned()}  (${formatPercent(pnlPercent)})',
                      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
