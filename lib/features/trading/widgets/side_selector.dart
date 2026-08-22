import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/order_side.dart';

class SideSelector extends StatelessWidget {
  const SideSelector({super.key, required this.value, required this.onChanged});

  final OrderSide value;
  final ValueChanged<OrderSide> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<OrderSide>(
      segments: [
        ButtonSegment(
          value: OrderSide.buy,
          label: const Text('Buy'),
          icon: const Icon(Icons.arrow_upward),
        ),
        ButtonSegment(
          value: OrderSide.sell,
          label: const Text('Sell'),
          icon: const Icon(Icons.arrow_downward),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        selectedForegroundColor: Colors.white,
        selectedBackgroundColor: value == OrderSide.buy ? MarketColors.up : MarketColors.down,
      ),
    );
  }
}
