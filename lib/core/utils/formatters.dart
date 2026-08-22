/// Formats a percentage value (already computed as a plain double, e.g.
/// from [percentChange] or a holding's P&L%) as `+1.23%` / `-0.45%`.
String formatPercent(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}

/// Formats an integer share quantity with thousands separators, e.g.
/// `12,500`.
String formatQuantity(int quantity) {
  final s = quantity.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return quantity < 0 ? '-${buffer.toString()}' : buffer.toString();
}
