import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/services/shell_service.dart';
import 'package:cuboid_flutter_template/features/home/ui/viewmodels/shell_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stacked_service_mocks.dart';

void main() {
  tearDown(locator.reset);

  test('reads and changes the shell index', () {
    final service = ShellService();
    replaceTestRegistration<ShellService>(service);
    final model = ShellViewModel();

    expect(model.index, 0);
    model.setIndex(2);
    expect(model.index, 2);
    expect(model.listenableServices, [service]);
  });

  test('stores money and work selections', () {
    final service = ShellService();
    service.setMoneySegment(MoneySegment.payments);
    service.setWorkFilter(WorkStatus.completed);

    expect(service.moneySegment, MoneySegment.payments);
    expect(service.workFilter, WorkStatus.completed);
    service.setWorkFilter(null);
    expect(service.workFilter, isNull);
  });
}
