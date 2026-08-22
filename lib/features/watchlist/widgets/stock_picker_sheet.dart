import 'package:flutter/material.dart';

import '../../../core/constants/stock_catalog.dart';

/// Bottom sheet listing all 10 tradable stocks, checked off if already in
/// the target watchlist. Tapping an unchecked stock adds it immediately
/// and closes the sheet -- fast, one-tap add, appropriate for a universe
/// this small.
class StockPickerSheet extends StatelessWidget {
  const StockPickerSheet({super.key, required this.alreadyAdded});

  final Set<String> alreadyAdded;

  static Future<String?> show(BuildContext context, {required Set<String> alreadyAdded}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StockPickerSheet(alreadyAdded: alreadyAdded),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Add a stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: StockCatalog.all.length,
                  itemBuilder: (context, index) {
                    final stock = StockCatalog.all[index];
                    final added = alreadyAdded.contains(stock.symbol);
                    return ListTile(
                      title: Text(stock.symbol, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(stock.name),
                      trailing: added
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.add_circle_outline),
                      enabled: !added,
                      onTap: added ? null : () => Navigator.of(context).pop(stock.symbol),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
