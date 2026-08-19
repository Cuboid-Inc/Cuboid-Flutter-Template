import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/services/navigation_service.dart';
import 'package:mocktail/mocktail.dart';

class MockNavigationService extends Mock implements NavigationService {}

void replaceTestRegistration<T extends Object>(T value) {
  if (locator.isRegistered<T>()) locator.unregister<T>();
  locator.registerSingleton<T>(value);
}
