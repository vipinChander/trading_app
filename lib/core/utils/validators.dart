/// Pure, side-effect-free validation helpers so both the UI (inline errors)
/// and the trading engine (defense in depth before mutating state) can
/// share a single source of truth for "is this input acceptable".
class Validators {
  Validators._();

  /// Validates a raw quantity string from a text field.
  ///
  /// Returns `null` when valid, otherwise a short user-facing error
  /// message. Rejects empty input, non-numeric input, fractional
  /// quantities, zero, negative numbers, and unreasonably large orders.
  static String? quantityInput(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Enter a quantity';

    final parsed = num.tryParse(trimmed);
    if (parsed == null) return 'Enter a valid whole number';

    if (parsed != parsed.roundToDouble()) {
      return 'Quantity must be a whole number of shares';
    }

    final asInt = parsed.toInt();
    if (asInt <= 0) return 'Quantity must be greater than zero';
    if (asInt > 1000000) return 'Quantity is unrealistically large';

    return null;
  }

  /// Parses a quantity string already known to be valid (call
  /// [quantityInput] first). Returns null if it somehow isn't parseable,
  /// so callers can still fail safe instead of throwing.
  static int? parseQuantity(String raw) {
    if (quantityInput(raw) != null) return null;
    return num.parse(raw.trim()).toInt();
  }

  static String? watchlistName(
    String raw, {
    required List<String> existingNames,
    String? currentName,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Enter a name';
    if (trimmed.length > 40) return 'Name is too long';
    final lower = trimmed.toLowerCase();
    final isDuplicate = existingNames
        .where((n) => n.toLowerCase() != currentName?.toLowerCase())
        .any((n) => n.toLowerCase() == lower);
    if (isDuplicate) return 'A watchlist with this name already exists';
    return null;
  }
}
