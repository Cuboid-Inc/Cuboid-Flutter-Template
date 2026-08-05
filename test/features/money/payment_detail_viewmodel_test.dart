import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/money/ui/payment_detail/payment_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

void main() {
  late MockMoneyRepository moneyRepository;
  late MockPartiesRepository partiesRepository;
  late MockSnackbarService snackbarService;
  late MockNavigationService navigationService;

  setUp(() {
    moneyRepository = MockMoneyRepository();
    partiesRepository = MockPartiesRepository();
    snackbarService = MockSnackbarService();
    navigationService = MockNavigationService();

    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<NavigationService>(navigationService);
  });

  tearDown(() {
    locator.reset();
  });

  test('init loads matching party, invoices, and settlements', () async {
    final payment = Payment(
      id: 'p1',
      direction: PaymentDirection.incoming,
      partyId: 'c1',
      date: DateTime.now(),
      amount: 1000.00,
      method: PaymentMethod.cheque,
      chequeState: ChequeState.received,
    );

    final party = Party(
      id: 'c1',
      name: 'Marina Build Co',
      type: PartyType.customer,
    );
    final invoice = Invoice(
      id: 'i1',
      number: 'INV-101',
      buyerId: 'c1',
      buyerName: 'Marina Build Co',
      issueDate: DateTime.now(),
      dueDate: DateTime.now(),
    );

    when(
      () => partiesRepository.fetchAll(),
    ).thenAnswer((_) async => Success([party]));
    when(
      () => moneyRepository.fetchInvoices(),
    ).thenAnswer((_) async => Success([invoice]));
    when(
      () => moneyRepository.fetchSettlements(),
    ).thenAnswer((_) async => const Success(<SupplierSettlement>[]));

    final model = PaymentDetailViewModel(
      payment,
      repository: moneyRepository,
      partiesRepository: partiesRepository,
    );

    await model.init();

    expect(model.party, party);
    expect(model.invoices, hasLength(1));
    expect(model.invoices.first.number, 'INV-101');
  });

  test('clearCheque clears cheque status via repository', () async {
    final payment = Payment(
      id: 'p1',
      direction: PaymentDirection.incoming,
      partyId: 'c1',
      date: DateTime.now(),
      amount: 1000.00,
      method: PaymentMethod.cheque,
      chequeState: ChequeState.received,
    );

    when(
      () => moneyRepository.transitionChequeState('p1', ChequeState.cleared),
    ).thenAnswer((_) async => const Success(null));

    final model = PaymentDetailViewModel(
      payment,
      repository: moneyRepository,
      partiesRepository: partiesRepository,
    );

    await model.clearCheque();

    expect(payment.chequeState, ChequeState.cleared);
  });
}
