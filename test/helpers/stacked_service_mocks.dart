import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

class MockNavigationService extends Mock implements NavigationService {}

class MockSnackbarService extends Mock implements SnackbarService {}

class MockBottomSheetService extends Mock implements BottomSheetService {}

class MockDialogService extends Mock implements DialogService {}

void replaceTestRegistration<T extends Object>(T value) {
  if (locator.isRegistered<T>()) locator.unregister<T>();
  locator.registerSingleton<T>(value);
}
