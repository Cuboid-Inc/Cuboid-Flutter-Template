import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/features/startup/startup_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

AuthAccess access() => const AuthAccess(
  memberId: 'm',
  tenantId: 't',
  tenantName: 'Tenant',
  email: 'a@b.com',
  displayName: 'A',
  role: StaffRole.staff,
  status: MembershipStatus.active,
  accessPacks: {AccessPack.reports},
);

void main() {
  late MockAuthRepository auth;
  late MockNavigationService navigation;
  setUp(() {
    auth = MockAuthRepository();
    navigation = MockNavigationService();
    replaceTestRegistration<AuthRepository>(auth);
    replaceTestRegistration<NavigationService>(navigation);
    when(
      () => navigation.replaceWith(any(), arguments: any(named: 'arguments')),
    ).thenAnswer((_) async => null);
  });
  tearDown(locator.reset);

  test('opens access unavailable on startup failure', () async {
    when(
      () => auth.resolveStartup(),
    ).thenAnswer((_) async => const Failure(NetworkFailure('offline')));
    await StartupViewModel().init();
    verify(
      () => navigation.replaceWith(
        Routes.accessUnavailableView,
        arguments: any(named: 'arguments'),
      ),
    ).called(1);
  });

  test('opens each startup destination', () async {
    for (final destination in AuthDestination.values) {
      when(() => auth.resolveStartup()).thenAnswer(
        (_) async => Success(
          AuthStartup(
            destination,
            destination == AuthDestination.invitation ? access() : null,
          ),
        ),
      );
      await StartupViewModel().init();
    }
    verify(() => navigation.replaceWith(Routes.loginView)).called(1);
    verify(() => navigation.replaceWith(Routes.shellView)).called(1);
    verify(() => navigation.replaceWith(Routes.resetPasswordView)).called(1);
    verify(
      () => navigation.replaceWith(
        Routes.acceptInvitationView,
        arguments: any(named: 'arguments'),
      ),
    ).called(1);
  });
}
