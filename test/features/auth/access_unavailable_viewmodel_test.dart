import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/auth/ui/access_unavailable/access_unavailable_viewmodel.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../helpers/stacked_service_mocks.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late MockNavigationService navigation;
  late MockSnackbarService snackbar;

  setUp(() {
    auth = MockAuthRepository();
    navigation = MockNavigationService();
    snackbar = MockSnackbarService();
    replaceTestRegistration<AuthRepository>(auth);
    replaceTestRegistration<NavigationService>(navigation);
    replaceTestRegistration<SnackbarService>(snackbar);
    when(() => navigation.clearStackAndShow(any())).thenAnswer((_) async => null);
  });
  tearDown(locator.reset);

  test('signOut navigates to login on success', () async {
    when(() => auth.signOut()).thenAnswer((_) async => const Success(null));
    await AccessUnavailableViewModel().signOut();
    verify(() => navigation.clearStackAndShow(Routes.loginView)).called(1);
  });

  test('signOut reports failure and retry opens startup', () async {
    when(() => auth.signOut()).thenAnswer(
      (_) async => const Failure(NetworkFailure('offline')),
    );
    await AccessUnavailableViewModel().signOut();
    verify(() => snackbar.showCustomSnackBar(message: 'offline', variant: SnackbarType.error)).called(1);
    await AccessUnavailableViewModel().retry();
    verify(() => navigation.clearStackAndShow(Routes.startupView)).called(1);
  });
}
