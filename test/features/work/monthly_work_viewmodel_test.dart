import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/more/data/agreement_repository.dart';
import 'package:cuboid_flutter_template/features/shell/shell_service.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:cuboid_flutter_template/features/work/ui/monthly_work/monthly_work_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockAgreementRepository extends Mock implements AgreementRepository {}

class MockWorkRepository extends Mock implements WorkRepository {}

class FakeWorkOrder extends Fake implements WorkOrder {}

Agreement agreement({String id = 'a', RateModel model = RateModel.monthly}) =>
    Agreement(
      id: id,
      reference: 'R',
      name: 'Monthly',
      customerId: 'c',
      rateModel: model,
      baseRate: 1000,
      overtimeRate: 20,
      extraDayRate: 30,
      extraTripRate: 40,
      defaultExtras: {'Parking': 5},
      defaultVehicleId: 'v',
    );

PaginatedResult<T> page<T>(List<T> items) => PaginatedResult(
  items: items,
  pageNumber: 1,
  pageSize: 50,
  totalRecords: items.length,
);

void main() {
  late MockAgreementRepository agreements;
  late MockWorkRepository work;
  late ShellService shell;
  late MockNavigationService navigation;
  late MockSnackbarService snackbar;
  setUpAll(() => registerFallbackValue(FakeWorkOrder()));
  setUp(() {
    agreements = MockAgreementRepository();
    work = MockWorkRepository();
    shell = ShellService();
    navigation = MockNavigationService();
    snackbar = MockSnackbarService();
    replaceTestRegistration<ShellService>(shell);
    replaceTestRegistration<NavigationService>(navigation);
    replaceTestRegistration<SnackbarService>(snackbar);
    when(() => navigation.back()).thenReturn(true);
  });
  tearDown(locator.reset);

  test('loads monthly agreements and manages charges', () async {
    final selected = agreement();
    when(
      () => agreements.fetchAgreementsPage(
        pageNumber: 1,
        pageSize: 50,
        search: null,
        rateModel: RateModel.monthly,
      ),
    ).thenAnswer((_) async => Success(page([selected])));
    final model = MonthlyWorkViewModel(
      agreementRepository: agreements,
      workRepository: work,
    );
    await model.init();
    final result = await model.fetchMonthlyAgreementsPage(pageNumber: 1);
    expect(result.valueOrNull?.items, hasLength(1));
    model.selectAgreement(selected);
    expect(model.agreement, isNotNull);
    expect(model.charges.single.isBaseLine, isTrue);
    expect(model.defaultRateFor(MonthlyExtraType.overtime), 20);
    expect(model.defaultRateFor(MonthlyExtraType.extraDay), 30);
    expect(model.defaultRateFor(MonthlyExtraType.extraTrip), 40);
    expect(model.defaultRateFor(MonthlyExtraType.parking), 5);
    model.addCharge(
      MonthlyExtraType.custom,
      quantity: 2,
      rate: 12.345,
      customName: ' Extra ',
    );
    expect(model.total, 1024.7);
    model.removeCharge(1);
    model.selectAgreement(null);
    expect(model.charges, isEmpty);
    expect(model.defaultRateFor(MonthlyExtraType.overtime), 0);
    model.setServiceDate(DateTime(2026, 7, 1));
  });

  test('validates steps and saves a work order', () async {
    final selected = agreement();
    when(
      () => agreements.fetchAgreements(),
    ).thenAnswer((_) async => Success([selected]));
    final created = WorkOrder(
      id: 'w',
      number: 'WO-1',
      customerId: 'c',
      agreementId: 'a',
      date: DateTime(2026, 7, 1),
      pickup: 'Monthly hire',
      destination: 'Monthly',
    );
    when(() => work.create(any())).thenAnswer((_) async => Success(created));
    final model = MonthlyWorkViewModel(
      agreementRepository: agreements,
      workRepository: work,
    );
    await model.init();
    await model.next();
    verify(
      () => snackbar.showCustomSnackBar(
        message: 'Please select an agreement',
        variant: SnackbarType.warning,
      ),
    ).called(1);
    model.selectAgreement(selected);
    await model.next();
    expect(model.step, 2);
    model.removeCharge(0);
    await model.next();
    verify(
      () => snackbar.showCustomSnackBar(
        message: 'Add at least one charge',
        variant: SnackbarType.warning,
      ),
    ).called(1);
    model.addCharge(MonthlyExtraType.parking, quantity: 1, rate: 5);
    await model.next();
    expect(model.step, 3);
    await model.next();
    verify(() => work.create(any())).called(1);
    expect(shell.index, 1);
    expect(shell.workFilter, WorkStatus.completed);
    verify(() => navigation.back()).called(1);
    verify(
      () => snackbar.showCustomSnackBar(
        message: 'WO-1 created',
        variant: SnackbarType.success,
      ),
    ).called(1);
    model.step = 2;
    model.back();
    expect(model.step, 1);
    model.back();
    verify(() => navigation.back()).called(1);
  });

  test('handles agreement page and save failures', () async {
    when(
      () => agreements.fetchAgreementsPage(
        pageNumber: 1,
        pageSize: 50,
        search: null,
        rateModel: RateModel.monthly,
      ),
    ).thenAnswer((_) async => const Failure(ValidationFailure('load failed')));
    final model = MonthlyWorkViewModel(
      agreementRepository: agreements,
      workRepository: work,
    );
    await model.init();
    final load = await model.fetchMonthlyAgreementsPage(pageNumber: 1);
    expect(load, isA<Failure<PaginatedResult<Agreement>>>());
    model.selectAgreement(agreement());
    when(
      () => work.create(any()),
    ).thenAnswer((_) async => const Failure(ValidationFailure('save failed')));
    model.step = 3;
    await model.next();
    verify(
      () => snackbar.showCustomSnackBar(
        message: 'save failed',
        variant: SnackbarType.error,
      ),
    ).called(1);
  });
}
