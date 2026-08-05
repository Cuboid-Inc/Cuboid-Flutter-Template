import 'dart:async';

import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/business_profile_repository.dart';
import 'package:cuboid_flutter_template/features/more/ui/business_profile/business_profile_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockBusinessProfileRepository extends Mock
    implements BusinessProfileRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeBusinessProfile extends Fake implements BusinessProfile {}

void main() {
  late MockBusinessProfileRepository repository;
  late MockSnackbarService snackbarService;
  late MockAuthRepository authRepository;
  late MockNavigationService navigationService;

  setUpAll(() => registerFallbackValue(FakeBusinessProfile()));

  setUp(() {
    repository = MockBusinessProfileRepository();
    snackbarService = MockSnackbarService();
    authRepository = MockAuthRepository();
    navigationService = MockNavigationService();
    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<NavigationService>(MockNavigationService());
    replaceTestRegistration<AuthRepository>(authRepository);
    replaceTestRegistration<NavigationService>(navigationService);
  });

  tearDown(locator.reset);

  test('save requires a legal business name', () async {
    final model = BusinessProfileViewModel(repository);

    await model.save();

    verifyNever(() => repository.updateBusinessProfile(any()));
    model.dispose();
  });

  for (final margin in ['invalid', 'NaN', '-1', '101']) {
    test('save rejects letterhead margin $margin', () async {
      final model = BusinessProfileViewModel(repository)
        ..legalNameController.text = 'Fleet Go'
        ..letterheadMarginTopController.text = margin;

      await model.save();

      verifyNever(() => repository.updateBusinessProfile(any()));
      model.dispose();
    });
  }

  test('save ignores a second call while the first is pending', () async {
    final pending = Completer<Result<BusinessProfile>>();
    when(
      () => repository.updateBusinessProfile(any()),
    ).thenAnswer((_) => pending.future);
    when(
      () => snackbarService.showCustomSnackBar(
        message: 'Save failed',
        variant: SnackbarType.error,
      ),
    ).thenAnswer((_) => null);
    final model = BusinessProfileViewModel(repository)
      ..legalNameController.text = 'Fleet Go';

    final first = model.save();
    await Future<void>.delayed(Duration.zero);
    final second = model.save();

    verify(() => repository.updateBusinessProfile(any())).called(1);
    pending.complete(const Failure(ValidationFailure('Save failed')));
    await Future.wait([first, second]);
    model.dispose();
  });

  test('init fills fields and computed letterhead state', () async {
    when(() => authRepository.currentTenantName).thenReturn('Tenant');
    when(() => repository.fetchBusinessProfile()).thenAnswer(
      (_) async => const Success(
        BusinessProfile(
          legalName: '',
          arabicLegalName: 'Arabic',
          trn: 'TRN',
          address: 'Address',
          city: 'Dubai',
          invoicePrefix: 'FG',
          brandColor: 7,
          useCustomLetterhead: true,
          letterheadPath: '/tmp/header.png',
          letterheadMarginTopMm: 10,
          letterheadMarginBottomMm: 20,
          letterheadMarginLeftMm: 30,
          letterheadMarginRightMm: 40,
        ),
      ),
    );
    final model = BusinessProfileViewModel(repository);
    await model.init();
    expect(model.legalNameController.text, 'Tenant');
    expect(model.invoicePrefixController.text, 'FG');
    expect(model.useCustomLetterhead, isTrue);
    model.letterheadWidth = 1000;
    model.letterheadHeight = 1000;
    expect(model.letterheadIsLowRes, isTrue);
    model.selectBrandColor(9);
    model.selectLetterheadMode(false);
    expect(model.brandColor, 9);
    expect(model.useCustomLetterhead, isFalse);
    model.dispose();
  });

  test('saves a valid profile and reports repository failure', () async {
    final model = BusinessProfileViewModel(repository)
      ..legalNameController.text = 'Fleet Go';
    when(() => repository.updateBusinessProfile(any())).thenAnswer(
      (_) async => const Success(BusinessProfile(legalName: 'Fleet Go')),
    );
    when(() => navigationService.back()).thenReturn(true);
    await model.save();
    verify(() => navigationService.back()).called(1);
    when(
      () => repository.updateBusinessProfile(any()),
    ).thenAnswer((_) async => const Failure(ValidationFailure('save failed')));
    await model.save();
    verify(
      () => snackbarService.showCustomSnackBar(
        message: 'save failed',
        variant: SnackbarType.error,
      ),
    ).called(1);
    model.dispose();
  });
}
