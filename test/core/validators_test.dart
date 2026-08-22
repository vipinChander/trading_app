import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/utils/validators.dart';

void main() {
  group('Validators.quantityInput', () {
    test('rejects empty input', () {
      expect(Validators.quantityInput(''), isNotNull);
      expect(Validators.quantityInput('   '), isNotNull);
    });

    test('rejects non-numeric input', () {
      expect(Validators.quantityInput('abc'), isNotNull);
      expect(Validators.quantityInput('12abc'), isNotNull);
    });

    test('rejects fractional quantities', () {
      expect(Validators.quantityInput('1.5'), isNotNull);
      expect(Validators.quantityInput('0.1'), isNotNull);
    });

    test('rejects zero and negative quantities', () {
      expect(Validators.quantityInput('0'), isNotNull);
      expect(Validators.quantityInput('-5'), isNotNull);
    });

    test('accepts a positive whole number', () {
      expect(Validators.quantityInput('1'), isNull);
      expect(Validators.quantityInput('250'), isNull);
    });

    test('rejects unreasonably large quantities', () {
      expect(Validators.quantityInput('99999999'), isNotNull);
    });

    test('parseQuantity only parses already-valid input', () {
      expect(Validators.parseQuantity('42'), 42);
      expect(Validators.parseQuantity('-1'), isNull);
      expect(Validators.parseQuantity('abc'), isNull);
    });
  });
}
