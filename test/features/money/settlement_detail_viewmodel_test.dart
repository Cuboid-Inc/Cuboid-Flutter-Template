import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/money/ui/settlement_detail/settlement_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/features/more/data/business_profile_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/payment_form/payment_form_sheet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

class MockWorkRepository extends Mock implements WorkRepository {}

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockBusinessProfileRepository extends Mock
    implements BusinessProfileRepository {}

void main() {
  late MockMoneyRepository moneyRepository;
  late MockPartiesRepository partiesRepository;
  late MockWorkRepository workRepository;
  late MockVehicleRepository vehicleRepository;
  late MockBusinessProfileRepository businessProfileRepository;
  late MockSnackbarService snackbarService;
  late MockNavigationService navigationService;
  late MockBottomSheetService bottomSheetService;
  late MockDialogService dialogService;

  setUp(() {
    moneyRepository = MockMoneyRepository();
    partiesRepository = MockPartiesRepository();
    workRepository = MockWorkRepository();
    vehicleRepository = MockVehicleRepository();
    businessProfileRepository = MockBusinessProfileRepository();
    snackbarService = MockSnackbarService();
    navigationService = MockNavigationService();
    bottomSheetService = MockBottomSheetService();
    dialogService = MockDialogService();

    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<NavigationService>(navigationService);
    replaceTestRegistration<BottomSheetService>(bottomSheetService);
    replaceTestRegistration<DialogService>(dialogService);
  });

  tearDown(() {
    locator.reset();
  });

  test('init loads matching supplier and settlement balance', () async {
    final settlement = SupplierSettlement(
      id: 'set-1',
      number: 'SET-2026-0041',
      supplierId: 'sup-1',
      periodStart: DateTime.now(),
      periodEnd: DateTime.now(),
      lines: [
        SettlementLine(
          workOrderId: 'work-1',
          date: DateTime(2026, 6, 1),
          amount: 1000.00,
        ),
      ],
    );

    final supplier = Party(
      id: 'sup-1',
      name: 'Desert Line Vehicles',
      type: PartyType.supplier,
    );

    when(
      () => partiesRepository.fetchAll(),
    ).thenAnswer((_) async => Success([supplier]));
    when(() => moneyRepository.fetchBalances()).thenAnswer(
      (_) async => Success(
        MoneyBalances(
          invoices: const {},
          settlements: {'set-1': 500.00},
          parties: const {},
        ),
      ),
    );
    when(() => businessProfileRepository.fetchBusinessProfile()).thenAnswer(
      (_) async => const Success(
        BusinessProfile(legalName: 'Test', address: 'Test', trn: '123'),
      ),
    );
    when(
      () => workRepository.fetchAll(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => vehicleRepository.fetchVehicles(),
    ).thenAnswer((_) async => const Success([]));

    final model = SettlementDetailViewModel(
      settlement,
      repository: moneyRepository,
      partiesRepository: partiesRepository,
      workRepository: workRepository,
      vehicleRepository: vehicleRepository,
      businessProfileRepository: businessProfileRepository,
    );

    await model.init();

    expect(model.supplier, supplier);
    expect(model.balance, 500.00);
  });

  test('viewWorkOrder navigates to WorkDetailView when found', () async {
    final settlement = SupplierSettlement(
      id: 'set-1',
      number: 'SET-2026-0041',
      supplierId: 'sup-1',
      periodStart: DateTime.now(),
      periodEnd: DateTime.now(),
    );

    final line = SettlementLine(
      workOrderId: 'work-1',
      date: DateTime(2026, 6, 1),
      amount: 1000.00,
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

    final model = SettlementDetailViewModel(
      settlement,
      repository: moneyRepository,
      partiesRepository: partiesRepository,
      workRepository: workRepository,
      vehicleRepository: vehicleRepository,
      businessProfileRepository: businessProfileRepository,
    );

    model.viewWorkOrder(line);

    verify(() => workRepository.fetchAll()).called(1);
  });

  test('records a payment and opens a prepared PDF', () async {
    final settlement = SupplierSettlement(
      id: 'set-1',
      number: 'SET-1',
      supplierId: 'sup-1',
      periodStart: DateTime(2026, 7),
      periodEnd: DateTime(2026, 7, 31),
    );
    final supplier = const Party(
      id: 'sup-1',
      name: 'Supplier',
      type: PartyType.supplier,
    );
    when(
      () => partiesRepository.fetchAll(),
    ).thenAnswer((_) async => Success([supplier]));
    when(() => moneyRepository.fetchBalances()).thenAnswer(
      (_) async => const Success(
        MoneyBalances(invoices: {}, settlements: {'set-1': 10}, parties: {}),
      ),
    );
    when(() => businessProfileRepository.fetchBusinessProfile()).thenAnswer(
      (_) async => const Success(BusinessProfile(legalName: 'FleetGo')),
    );
    final payment = Payment(
      id: 'p',
      direction: PaymentDirection.outgoing,
      partyId: 'sup-1',
      date: DateTime(2026, 7),
      amount: 10,
      method: PaymentMethod.cash,
    );
    when(
      () => bottomSheetService.showCustomSheet<Payment, PaymentFormData>(
        variant: any(named: 'variant'),
        data: any(named: 'data'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer((_) async => SheetResponse(data: payment));
    when(
      () => moneyRepository.recordPayment(payment),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => workRepository.fetchAll(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => vehicleRepository.fetchVehicles(),
    ).thenAnswer((_) async => const Success([]));
    final model = SettlementDetailViewModel(
      settlement,
      repository: moneyRepository,
      partiesRepository: partiesRepository,
      workRepository: workRepository,
      vehicleRepository: vehicleRepository,
      businessProfileRepository: businessProfileRepository,
    );
    await model.init();
    await model.recordPayment();
    verify(() => moneyRepository.recordPayment(payment)).called(1);
    model.openPdf();
    verify(
      () => navigationService.navigateTo(
        any(),
        arguments: any(named: 'arguments'),
      ),
    ).called(1);
  });
}
