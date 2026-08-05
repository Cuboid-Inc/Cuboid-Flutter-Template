import 'package:cuboid_flutter_template/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('roundMoney rounds positive and negative half cents away from zero', () {
    expect(roundMoney(1.005), 1.01);
    expect(roundMoney(-1.005), -1.01);
    expect(roundMoney(1.004), 1.00);
    expect(roundMoney(-1.004), -1.00);
    expect(roundMoney(1.0049), 1.00);
    expect(roundMoney(-1.0049), -1.00);
  });

  test('vatAmount rounds at the VAT calculation boundary', () {
    expect(vatAmount(0.10, 5), 0.01);
    expect(vatAmount(10.10, 5), 0.51);
  });
}
