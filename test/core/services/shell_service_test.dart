import 'package:cuboid_flutter_template/core/services/shell_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores the active shell index', () {
    final service = ShellService();

    expect(service.index, 0);
    service.setIndex(1);

    expect(service.index, 1);
  });

  test('notifies listeners when the active shell index changes', () async {
    final service = ShellService();
    var notificationCount = 0;
    service.addListener(() => notificationCount++);

    service.setIndex(1);
    await Future<void>.delayed(Duration.zero);

    expect(notificationCount, greaterThan(0));
  });
}
