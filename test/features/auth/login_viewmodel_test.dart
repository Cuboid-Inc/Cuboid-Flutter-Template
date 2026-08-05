import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/auth/ui/login/login_viewmodel.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../helpers/stacked_service_mocks.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

AuthAccess access() => const AuthAccess(
  memberId: 'm', tenantId: 't', tenantName: 'Tenant', email: 'a@b.com',
  displayName: 'A', role: StaffRole.staff, status: MembershipStatus.active,
  accessPacks: {AccessPack.money},
);

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
    when(() => navigation.replaceWith(any(), arguments: any(named: 'arguments')))
        .thenAnswer((_) async => null);
  });
  tearDown(locator.reset);

  test('validates credentials and signs in to shell', () async {
    final model = LoginViewModel();
    expect(model.canSignIn, isFalse);
    model.emailController.text = 'user@example.com';
    model.passwordController.text = 'password';
    expect(model.canSignIn, isTrue);
    when(() => auth.signIn(email: 'user@example.com', password: 'password'))
        .thenAnswer((_) async => const Success(AuthStartup(AuthDestination.signedIn)));
    await model.signIn();
    verify(() => navigation.replaceWith(Routes.shellView)).called(1);
    model.forgotPassword();
    verify(() => navigation.navigateTo(Routes.forgotPasswordView)).called(1);
    model.dispose();
  });

  test('shows sign in failure and handles every destination', () async {
    final model = LoginViewModel();
    model.emailController.text = 'user@example.com';
    model.passwordController.text = 'password';
    when(() => auth.signIn(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Failure(AuthFailure('bad login')));
    await model.signIn();
    verify(() => snackbar.showCustomSnackBar(message: 'bad login', variant: SnackbarType.error)).called(1);
    for (final destination in AuthDestination.values) {
      when(() => auth.signIn(email: 'user@example.com', password: 'password'))
          .thenAnswer((_) async => Success(AuthStartup(destination,
            destination == AuthDestination.invitation ? access() : null)));
      await model.signIn();
    }
    verify(() => navigation.replaceWith(Routes.acceptInvitationView,
      arguments: any(named: 'arguments'))).called(1);
    verify(() => navigation.replaceWith(Routes.accessUnavailableView,
      arguments: any(named: 'arguments'))).called(1);
    model.dispose();
  });
}
