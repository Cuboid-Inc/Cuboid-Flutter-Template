import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/features/auth/ui/forgot_password/forgot_password_viewmodel.dart';
import 'package:fleetgo/features/auth/ui/reset_password/reset_password_viewmodel.dart';
import 'package:fleetgo/features/auth/ui/accept_invitation/accept_invitation_viewmodel.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../helpers/stacked_service_mocks.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockNavigationService navigationService;
  late MockSnackbarService snackbarService;
  late MockAuthRepository authRepository;

  setUpAll(() {
    registerFallbackValue(Routes.loginView);
    registerFallbackValue(Routes.shellView);
  });

  setUp(() {
    navigationService = MockNavigationService();
    snackbarService = MockSnackbarService();
    authRepository = MockAuthRepository();

    replaceTestRegistration<NavigationService>(navigationService);
    replaceTestRegistration<SnackbarService>(snackbarService);
    if (locator.isRegistered<AuthRepository>()) {
      locator.unregister<AuthRepository>();
    }

    locator.registerSingleton<AuthRepository>(authRepository);

    when(() => navigationService.back()).thenReturn(true);
  });

  tearDown(() {
    locator.reset();
  });

  group('ForgotPasswordViewModel -', () {
    test('sendResetEmail rejects an invalid email', () async {
      final model = ForgotPasswordViewModel();
      await model.sendResetEmail();
      verifyNever(() => authRepository.sendPasswordReset(any()));
    });

    test(
      'sendResetEmail submits email via repository and navigates back',
      () async {
        final model = ForgotPasswordViewModel();
        model.emailController.text = 'test@example.com';

        when(
          () => authRepository.sendPasswordReset('test@example.com'),
        ).thenAnswer((_) async => const Success(null));
        await model.sendResetEmail();

        verify(
          () => authRepository.sendPasswordReset('test@example.com'),
        ).called(1);
        verify(() => navigationService.back()).called(1);
      },
    );
  });

  group('ResetPasswordViewModel -', () {
    test('submitReset rejects a short password', () async {
      final model = ResetPasswordViewModel();
      await model.submitReset();
      verifyNever(() => authRepository.resetPassword(any()));
    });

    test('submitReset with non-matching passwords shows snackbar', () async {
      final model = ResetPasswordViewModel();
      model.passwordController.text = 'password1';
      model.confirmPasswordController.text = 'password2';
      await model.submitReset();
      verifyNever(() => authRepository.resetPassword(any()));
    });

    test(
      'submitReset resets password via repository and navigates to login',
      () async {
        final model = ResetPasswordViewModel();
        model.passwordController.text = 'password';
        model.confirmPasswordController.text = 'password';

        when(
          () => authRepository.resetPassword('password'),
        ).thenAnswer((_) async => const Success(null));
        when(
          () => navigationService.clearStackAndShow(any()),
        ).thenAnswer((_) async => null);

        await model.submitReset();

        verify(() => authRepository.resetPassword('password')).called(1);
        verify(
          () => navigationService.clearStackAndShow(Routes.loginView),
        ).called(1);
      },
    );
  });

  group('AcceptInvitationViewModel -', () {
    test('acceptInvitation rejects a short password', () async {
      final model = AcceptInvitationViewModel(
        email: 'staff@almasar.ae',
        businessName: 'Al Masar',
        accessPacks: [AccessPack.operations],
      );
      await model.acceptInvitation();
      verifyNever(
        () => authRepository.acceptInvitation(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test(
      'acceptInvitation with non-matching passwords shows snackbar',
      () async {
        final model = AcceptInvitationViewModel(
          email: 'staff@almasar.ae',
          businessName: 'Al Masar',
          accessPacks: [AccessPack.operations],
        );
        model.passwordController.text = 'password1';
        model.confirmPasswordController.text = 'password2';
        await model.acceptInvitation();
        verifyNever(
          () => authRepository.acceptInvitation(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    test(
      'acceptInvitation accepts via repository and navigates to shell',
      () async {
        final model = AcceptInvitationViewModel(
          email: 'staff@almasar.ae',
          businessName: 'Al Masar',
          accessPacks: [AccessPack.operations],
        );
        model.passwordController.text = 'password';
        model.confirmPasswordController.text = 'password';

        when(
          () => authRepository.acceptInvitation(
            email: 'staff@almasar.ae',
            password: 'password',
          ),
        ).thenAnswer(
          (_) async => const Success(AuthStartup(AuthDestination.signedIn)),
        );
        when(
          () => navigationService.replaceWith(any()),
        ).thenAnswer((_) async => null);

        await model.acceptInvitation();

        verify(
          () => authRepository.acceptInvitation(
            email: 'staff@almasar.ae',
            password: 'password',
          ),
        ).called(1);
        verify(() => navigationService.replaceWith(Routes.shellView)).called(1);
      },
    );
  });
}
