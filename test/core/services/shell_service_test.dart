import 'package:nemara_homes/core/services/shell_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores the active shell index', () {
    final service = ShellService();

    expect(service.index, 0);
    service.setIndex(1);

    expect(service.index, 1);
  });
}
