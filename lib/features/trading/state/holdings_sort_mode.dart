import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HoldingsSortMode {
  pnlDesc('P&L (high to low)'),
  symbolAsc('Symbol (A-Z)'),
  valueDesc('Current value (high to low)');

  const HoldingsSortMode(this.label);
  final String label;
}

/// Default sort is P&L descending, per the assignment spec.
final holdingsSortModeProvider = StateProvider<HoldingsSortMode>((ref) => HoldingsSortMode.pnlDesc);
