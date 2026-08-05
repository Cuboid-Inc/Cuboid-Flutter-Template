import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/features/shell/shell_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores all shell selections', () {
    final service = ShellService();
    expect(service.index, 0);
    expect(service.moneySegment, MoneySegment.invoices);
    expect(service.workFilter, isNull);
    service.setIndex(1);
    service.setMoneySegment(MoneySegment.balances);
    service.setWorkFilter(WorkStatus.billed);
    expect(service.index, 1);
    expect(service.moneySegment, MoneySegment.balances);
    expect(service.workFilter, WorkStatus.billed);
  });
}
