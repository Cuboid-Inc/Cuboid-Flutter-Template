import 'dart:async';

import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/report_models.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/features/work/ui/prepare_month/prepare_month_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

class FakeInvoice extends Fake implements Invoice {}

void main() {
  late MockMoneyRepository moneyRepository;
  late MockPartiesRepository partiesRepository;
  late MockSnackbarService snackbarService;

  setUpAll(() => registerFallbackValue(FakeInvoice()));

  setUp(() {
    moneyRepository = MockMoneyRepository();
    partiesRepository = MockPartiesRepository();
    snackbarService = MockSnackbarService();
    replaceTestRegistration<NavigationService>(MockNavigationService());
    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<BottomSheetService>(MockBottomSheetService());
  });

  tearDown(locator.reset);

  test('issue ignores a second call while the first is pending', () async {
    const customer = Party(
      id: 'customer',
      name: 'Customer',
      type: PartyType.customer,
    );
    final work = WorkOrder(
      id: 'work',
      number: 'WO-1',
      customerId: customer.id,
      agreementId: 'agreement',
      date: DateTime(2026, 7),
      pickup: 'A',
      destination: 'B',
      status: WorkStatus.completed,
      chargeLines: const [ChargeLine(name: 'Transport', unitPrice: 10)],
    );
    when(
      () => partiesRepository.fetchAll(),
    ).thenAnswer((_) async => const Success([customer]));
    when(() => moneyRepository.fetchUnbilledWork()).thenAnswer(
      (_) async => Success([
        UnbilledWorkRow(workOrder: work, customerName: customer.name),
      ]),
    );
    final pending = Completer<Result<Invoice>>();
    when(
      () => moneyRepository.issueInvoice(any()),
    ).thenAnswer((_) => pending.future);
    when(
      () => snackbarService.showCustomSnackBar(
        message: 'Issue failed',
        variant: SnackbarType.error,
      ),
    ).thenAnswer((_) => null);
    final model = PrepareMonthViewModel(
      moneyRepository: moneyRepository,
      partiesRepository: partiesRepository,
    );
    await model.init();
    model.selectCustomer(customer);
    // selectCustomer now pre-selects every eligible work order by default,
    // so work.id is already selected here.

    final first = model.issue();
    await Future<void>.delayed(Duration.zero);
    final second = model.issue();

    verify(() => moneyRepository.issueInvoice(any())).called(1);
    pending.complete(const Failure(ValidationFailure('Issue failed')));
    await Future.wait([first, second]);
  });
}
