import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/services/shell_service.dart';
import 'package:cuboid_flutter_template/features/home/ui/viewmodels/shell_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/stacked_service_mocks.dart';

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
}
