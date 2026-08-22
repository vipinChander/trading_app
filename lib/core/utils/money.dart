import 'package:intl/intl.dart';

/// Represents an amount of Indian Rupees with exact precision.
///
/// Money is stored internally as an integer number of paise (1 rupee = 100
/// paise). Every arithmetic operation stays in integer space, so there is
/// never any floating point drift in balances, order values, or P&L figures
/// -- the kind of drift you'd get by doing `double` arithmetic on currency.
///
/// The only place a `double` is allowed near money is when *deriving* a
/// percentage for display (change%, P&L%), which is inherently a ratio and
/// not itself a currency amount.
class Money implements Comparable<Money> {
  const Money.fromPaise(this.paise);

  /// Convenience constructor for literals in code (e.g. starting prices).
  factory Money.fromRupees(num rupees) {
    return Money.fromPaise((rupees * 100).round());
  }

  static const Money zero = Money.fromPaise(0);

  /// The exact amount, in paise (1/100th of a rupee). Always an integer.
  final int paise;

  double get rupees => paise / 100;

  bool get isNegative => paise < 0;
  bool get isZero => paise == 0;

  Money operator +(Money other) => Money.fromPaise(paise + other.paise);
  Money operator -(Money other) => Money.fromPaise(paise - other.paise);

  /// Multiply by a whole-share quantity. Order value math (qty * price)
  /// always goes through this so it never touches a double.
  Money operator *(int quantity) => Money.fromPaise(paise * quantity);

  Money operator -() => Money.fromPaise(-paise);

  bool operator <(Money other) => paise < other.paise;
  bool operator <=(Money other) => paise <= other.paise;
  bool operator >(Money other) => paise > other.paise;
  bool operator >=(Money other) => paise >= other.paise;

  @override
  bool operator ==(Object other) => other is Money && other.paise == paise;

  @override
  int get hashCode => paise.hashCode;

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats as `₹1,23,456.78`. Negative amounts render as `-₹1,234.00`.
  String format() {
    if (isNegative) {
      return '-${_formatter.format(-rupees)}';
    }
    return _formatter.format(rupees);
  }

  /// Same as [format] but prefixes a `+` for positive amounts, useful for
  /// change/P&L columns where sign carries meaning.
  String formatSigned() {
    if (isNegative) return format();
    if (isZero) return format();
    return '+${format()}';
  }

  int toJson() => paise;

  factory Money.fromJson(dynamic json) => Money.fromPaise((json as num).round());

  @override
  String toString() => format();
}

/// Computes a percentage change of [current] relative to [base] as a plain
/// double for display only (never stored, never fed back into money math).
double percentChange({required Money base, required Money current}) {
  if (base.paise == 0) return 0;
  return ((current.paise - base.paise) / base.paise) * 100;
}
