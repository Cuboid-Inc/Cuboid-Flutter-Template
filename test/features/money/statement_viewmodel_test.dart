import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/period.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/money/data/money_rows.dart';
import 'package:cuboid_flutter_template/features/money/ui/statement_view/statement_viewmodel.dart';
import 'package:cuboid_flutter_template/features/more/data/business_profile_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

class MockWorkRepository extends Mock implements WorkRepository {}

class MockBusinessProfileRepository extends Mock
    implements BusinessProfileRepository {}

void main() {
  late MockMoneyRepository moneyRepository;
  late MockPartiesRepository partiesRepository;
  late MockWorkRepository workRepository;
  late MockBusinessProfileRepository businessProfileRepository;
  late MockSnackbarService snackbarService;
  late MockNavigationService navigationService;

  setUp(() {
    moneyRepository = MockMoneyRepository();
    partiesRepository = MockPartiesRepository();
    workRepository = MockWorkRepository();
    businessProfileRepository = MockBusinessProfileRepository();
    snackbarService = MockSnackbarService();
    navigationService = MockNavigationService();

    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<NavigationService>(navigationService);
    if (locator.isRegistered<BusinessProfileRepository>()) {
      locator.unregister<BusinessProfileRepository>();
    }
    locator.registerSingleton<BusinessProfileRepository>(
      businessProfileRepository,
    );
  });

  tearDown(() {
    locator.reset();
  });

  test('init loads matching statement details', () async {
    final period = Period.month(2026, 6);
    final party = Party(
      id: 'p1',
      name: 'Marina Build Co',
      type: PartyType.customer,
    );
    final statementRow = StatementRow(
      partyId: 'p1',
      date: DateTime(2026, 6, 15),
      workOrderId: 'work-1',
      description: 'Trip 101',
      amount: 2500.00,
    );

    when(
      () => partiesRepository.fetchAll(),
    ).thenAnswer((_) async => Success([party]));
    when(
      () => moneyRepository.statementRows(period),
    ).thenAnswer((_) async => Success([statementRow]));
    when(
      () => workRepository.fetchAll(),
    ).thenAnswer((_) async => const Success([]));
    when(() => businessProfileRepository.fetchBusinessProfile()).thenAnswer(
      (_) async => const Success(
        BusinessProfile(legalName: 'Test', address: 'Test', trn: '123'),
      ),
    );

    final model = StatementViewModel(
      partyId: 'p1',
      period: period,
      repository: moneyRepository,
      partiesRepository: partiesRepository,
      workRepository: workRepository,
    );

    await model.init();

    expect(model.party, party);
    expect(model.rows, hasLength(1));
    expect(model.rows.first.workOrderId, 'work-1');
    expect(model.total, 2500.00);
  });

  test('viewWorkOrder navigates to WorkDetailView when found', () async {
    final period = Period.month(2026, 6);
    final row = StatementRow(
      partyId: 'p1',
      date: DateTime(2026, 6, 15),
      workOrderId: 'work-1',
      description: 'Trip 101',
      amount: 2500.00,
    );
    final workOrder = WorkOrder(
      id: 'work-1',
      number: 'WO-101',
      customerId: 'p1',
      agreementId: 'a1',
      date: DateTime.now(),
      pickup: 'A',
      destination: 'B',
    );

    when(
      () => workRepository.fetchAll(),
    ).thenAnswer((_) async => Success([workOrder]));
    registerFallbackValue(WorkDetailViewArguments(work: workOrder));
    when(
      () => navigationService.navigateTo(
        any(),
        arguments: any(named: 'arguments'),
      ),
    ).thenAnswer((_) async => null);

    final model = StatementViewModel(
      partyId: 'p1',
      period: period,
      repository: moneyRepository,
      partiesRepository: partiesRepository,
      workRepository: workRepository,
    );

    model.viewWorkOrder(row);

    verify(() => workRepository.fetchAll()).called(1);
  });
}
