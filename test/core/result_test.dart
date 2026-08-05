import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

String describe(Result<int> result) => switch (result) {
  Success(:final value) => 'ok:$value',
  Failure(:final failure) => 'err:${failure.message}',
};

void main() {
  test('exhaustive switch handles Success and Failure', () {
    const success = Success<int>(42);
    const failure = Failure<int>(ValidationFailure('bad input'));

    expect(describe(success), 'ok:42');
    expect(describe(failure), 'err:bad input');
    expect(success.isSuccess, isTrue);
    expect(failure.isSuccess, isFalse);
    expect(success.valueOrNull, 42);
    expect(failure.valueOrNull, isNull);
  });

  test('Formatters.money renders AED with two decimals', () {
    expect(Formatters.money(1250), 'AED 1,250.00');
  });

  test('Formatters.parseMoney rounds AED input half up', () {
    expect(Formatters.parseMoney('1,081.665'), 1081.67);
    expect(Formatters.parseMoney('invalid'), isNull);
  });

  test('Formatters.date uses the configured day-first pattern', () {
    expect(Formatters.date(DateTime(2026, 7, 12)), '12 Jul 2026');
  });

  test('Formatters.monthYear uses the configured pattern', () {
    expect(Formatters.monthYear(DateTime(2026, 7, 12)), 'July 2026');
  });
}
