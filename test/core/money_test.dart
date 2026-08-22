import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/utils/money.dart';

void main() {
  group('Money', () {
    test('stores exact paise with no floating point drift', () {
      final a = Money.fromRupees(10.10);
      final b = Money.fromRupees(0.20);
      // Naive double math (10.10 + 0.20) famously prints 10.299999999999999
      // in most languages. Money must not reproduce that.
      expect((a + b).paise, 1030);
      expect((a + b).rupees, 10.30);
    });

    test('multiplying by a quantity matches manual paise math', () {
      const price = Money.fromPaise(24575); // 245.75
      final orderValue = price * 37;
      expect(orderValue.paise, 24575 * 37);
    });

    test('formats as Indian rupees with two decimal digits', () {
      const money = Money.fromPaise(123456);
      expect(money.format(), contains('1,234.56'));
    });

    test('formatSigned adds a plus for positive amounts only', () {
      expect(Money.fromRupees(5).formatSigned().startsWith('+'), isTrue);
      expect(Money.fromRupees(-5).formatSigned().startsWith('-'), isTrue);
      expect(Money.zero.formatSigned().startsWith('+'), isFalse);
    });

    test('comparison operators order by paise', () {
      expect(Money.fromRupees(10) < Money.fromRupees(20), isTrue);
      expect(Money.fromRupees(20) > Money.fromRupees(10), isTrue);
      expect(Money.fromRupees(10) <= Money.fromRupees(10), isTrue);
    });

    test('round-trips through JSON', () {
      final money = Money.fromRupees(999.99);
      final restored = Money.fromJson(money.toJson());
      expect(restored, money);
    });
  });

  group('percentChange', () {
    test('computes a signed percentage relative to base', () {
      final base = Money.fromRupees(100);
      final current = Money.fromRupees(110);
      expect(percentChange(base: base, current: current), closeTo(10.0, 0.0001));
    });

    test('returns 0 when base is zero, instead of dividing by zero', () {
      expect(percentChange(base: Money.zero, current: Money.fromRupees(10)), 0);
    });
  });
}
