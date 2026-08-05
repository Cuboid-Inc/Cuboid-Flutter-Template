import 'package:fleetgo/features/auth/data/auth_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth fields reject malformed email and short password', () {
    expect(isValidEmail('owner@example.com'), isTrue);
    expect(isValidEmail('owner@example'), isFalse);
    expect(passwordError('1234567'), isNotNull);
    expect(passwordError('12345678'), isNull);
  });
}
