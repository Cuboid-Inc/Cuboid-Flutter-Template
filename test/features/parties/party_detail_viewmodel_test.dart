import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/features/parties/ui/party_detail/party_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

class MockWorkRepository extends Mock implements WorkRepository {}

void main() {
  late MockMoneyRepository moneyRepository;
  late MockPartiesRepository partiesRepository;
  late MockWorkRepository workRepository;
  late MockSnackbarService snackbarService;
  late MockNavigationService navigationService;
  late MockBottomSheetService bottomSheetService;

  setUp(() {
    moneyRepository = MockMoneyRepository();
    partiesRepository = MockPartiesRepository();
    workRepository = MockWorkRepository();
    snackbarService = MockSnackbarService();
    navigationService = MockNavigationService();
    bottomSheetService = MockBottomSheetService();

    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<NavigationService>(navigationService);
    replaceTestRegistration<BottomSheetService>(bottomSheetService);
  });

  tearDown(() {
    locator.reset();
  });

  test('init loads invoices and balance for party', () async {
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

    const mockPartyBalances = MoneyBalances(
      invoices: {'i1': 2000.00},
      settlements: {},
      parties: {'c1': 2000.00},
    );

    when(
      () => moneyRepository.fetchInvoices(),
    ).thenAnswer((_) async => Success([invoice]));
    when(
      () => workRepository.fetchAll(),
    ).thenAnswer((_) async => const Success(<WorkOrder>[]));
    when(
      () => moneyRepository.fetchBalances(),
    ).thenAnswer((_) async => const Success(mockPartyBalances));

    final model = PartyDetailViewModel(
      party,
      moneyRepository: moneyRepository,
      partiesRepository: partiesRepository,
      workRepository: workRepository,
    );

    await model.init();

    expect(model.invoices, hasLength(1));
    expect(model.balance, 2000.00);
  });

  test('editParty shows bottom sheet and updates party info', () async {
    final party = Party(
      id: 'c1',
      name: 'Marina Build Co',
      type: PartyType.customer,
    );
    final updatedParty = Party(
      id: 'c1',
      name: 'Marina Refactored Co',
      type: PartyType.customer,
    );

    when(
      () => bottomSheetService.showCustomSheet<Party, Party>(
        variant: any(named: 'variant'),
        data: any(named: 'data'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer(
      (_) async => SheetResponse(confirmed: true, data: updatedParty),
    );

    when(
      () => partiesRepository.create(updatedParty),
    ).thenAnswer((_) async => Success(updatedParty));
    when(
      () => moneyRepository.fetchInvoices(),
    ).thenAnswer((_) async => const Success(<Invoice>[]));
    when(
      () => workRepository.fetchAll(),
    ).thenAnswer((_) async => const Success(<WorkOrder>[]));
    when(() => moneyRepository.fetchBalances()).thenAnswer(
      (_) async => const Success(
        MoneyBalances(invoices: {}, settlements: {}, parties: {}),
      ),
    );

    final model = PartyDetailViewModel(
      party,
      moneyRepository: moneyRepository,
      partiesRepository: partiesRepository,
      workRepository: workRepository,
    );

    await model.editParty();

    expect(model.party.name, 'Marina Refactored Co');
  });

  test('archiveParty calls repository and navigates back', () async {
    final party = Party(
      id: 'c1',
      name: 'Marina Build Co',
      type: PartyType.customer,
    );

    when(
      () => partiesRepository.archive('c1'),
    ).thenAnswer((_) async => const Success(null));
    when(() => navigationService.back()).thenReturn(true);

    final model = PartyDetailViewModel(
      party,
      moneyRepository: moneyRepository,
      partiesRepository: partiesRepository,
      workRepository: workRepository,
    );

    await model.archiveParty();

    verify(() => partiesRepository.archive('c1')).called(1);
    verify(() => navigationService.back()).called(1);
  });
}
