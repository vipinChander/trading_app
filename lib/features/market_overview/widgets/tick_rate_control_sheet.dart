import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/market/market_data_providers.dart';

/// Debug control for the mock feed's tick rate. Lets a reviewer directly
/// exercise the "5+ ticks/sec/stock = 50+/sec overall, UI stays smooth"
/// scenario from the assignment via a one-tap stress-test button, or
/// dial in any rate with the slider.
class TickRateControlSheet extends ConsumerWidget {
  const TickRateControlSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const TickRateControlSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rate = ref.watch(tickRateProvider);

    void setRate(double value) {
      ref.read(tickRateProvider.notifier).state = value;
      ref.read(marketDataServiceProvider).updateTickRate(value);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Feed tick rate', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${rate.toStringAsFixed(1)} ticks/sec per stock  ·  '
              '~${(rate * 10).toStringAsFixed(0)} ticks/sec overall (10 stocks)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Slider(
              value: rate.clamp(0.2, 10.0).toDouble(),
              min: 0.2,
              max: 10.0,
              divisions: 49,
              label: rate.toStringAsFixed(1),
              onChanged: setRate,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setRate(kDefaultTickRate),
                    child: const Text('Realistic (1/sec)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => setRate(kStressTestTickRate),
                    child: const Text('Stress test (5/sec)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
