import 'package:nemara_homes/app/app.locator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

class MockNavigationService extends Mock implements NavigationService {}

void replaceTestRegistration<T extends Object>(T value) {
  if (locator.isRegistered<T>()) locator.unregister<T>();
  locator.registerSingleton<T>(value);
}
