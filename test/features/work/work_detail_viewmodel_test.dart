import 'dart:async';

import 'package:cuboid_flutter_template/app/app.dialogs.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/core/models/expense.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/agreement_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/business_profile_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/driver_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:cuboid_flutter_template/features/work/ui/work_detail/work_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockWorkRepository extends Mock implements WorkRepository {}

class MockAgreementRepository extends Mock implements AgreementRepository {}

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockDriverRepository extends Mock implements DriverRepository {}

class MockBusinessProfileRepository extends Mock
    implements BusinessProfileRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockWorkRepository workRepository;
  late MockAgreementRepository agreementRepository;
  late MockVehicleRepository vehicleRepository;
  late MockDriverRepository driverRepository;
  late MockBusinessProfileRepository businessProfileRepository;
  late MockPartiesRepository partiesRepository;
  late MockMoneyRepository moneyRepository;
  late MockAuthRepository authRepository;
  late MockSnackbarService snackbarService;
  late MockDialogService dialogService;
  late MockNavigationService navigationService;

  setUp(() {
    workRepository = MockWorkRepository();
    agreementRepository = MockAgreementRepository();
    vehicleRepository = MockVehicleRepository();
    driverRepository = MockDriverRepository();
    businessProfileRepository = MockBusinessProfileRepository();
    partiesRepository = MockPartiesRepository();
    moneyRepository = MockMoneyRepository();
    authRepository = MockAuthRepository();
    snackbarService = MockSnackbarService();
    dialogService = MockDialogService();
    navigationService = MockNavigationService();

    if (locator.isRegistered<AuthRepository>()) {
      locator.unregister<AuthRepository>();
    }
    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<DialogService>(dialogService);
    replaceTestRegistration<NavigationService>(navigationService);
    locator.registerSingleton<AuthRepository>(authRepository);
  });

  tearDown(() {
    locator.reset();
  });

  test(
    'init loads matching details and calculates totalSupplierPayable',
    () async {
      final workOrder = WorkOrder(
        id: 'work-1',
        number: 'WO-1039',
        customerId: 'c1',
        agreementId: 'a12',
        date: DateTime.now(),
        pickup: 'Monthly hire',
        destination: 'Sunday work',
        invoiceId: 'i268',
        allocations: [
          const VehicleAllocation(
            vehicleId: 'v3',
            driverId: 'd3',
            source: VehicleSource.owned,
          ),
          const VehicleAllocation(
            vehicleId: 'v4',
            driverId: 'd1',
            source: VehicleSource.supplier,
            supplierId: 's1',
            supplierPayable: 500.00,
          ),
        ],
      );

      final customer = Party(
        id: 'c1',
        name: 'Gulf Star',
        type: PartyType.customer,
      );
      final agreement = Agreement(
        id: 'a12',
        reference: 'AGR-012',
        name: 'Gulf Star monthly',
        customerId: 'c1',
        rateModel: RateModel.monthly,
      );
      final invoice = Invoice(
        id: 'i268',
        number: 'INV-2026-003268',
        buyerId: 'c1',
        buyerName: 'Gulf Star',
        issueDate: DateTime.now(),
        dueDate: DateTime.now(),
        lines: const [],
      );
      final expense = Expense(
        id: 'e1',
        date: DateTime.now(),
        category: ExpenseCategory.fuel,
        payee: 'ENOC',
        net: 850.00,
        workOrderId: 'work-1',
      );

      when(
        () => partiesRepository.fetchAll(),
      ).thenAnswer((_) async => Success([customer]));
      when(
        () => agreementRepository.fetchAgreements(),
      ).thenAnswer((_) async => Success([agreement]));
      when(
        () => vehicleRepository.fetchVehicles(),
      ).thenAnswer((_) async => const Success(<Vehicle>[]));
      when(
        () => driverRepository.fetchDrivers(),
      ).thenAnswer((_) async => const Success(<Driver>[]));
      when(() => businessProfileRepository.fetchBusinessProfile()).thenAnswer(
        (_) async => const Success(
          BusinessProfile(legalName: 'Test', address: 'Test', trn: '123'),
        ),
      );
      when(
        () => moneyRepository.fetchInvoices(),
      ).thenAnswer((_) async => Success([invoice]));
      when(
        () => moneyRepository.fetchExpenses(),
      ).thenAnswer((_) async => Success([expense]));

      final model = WorkDetailViewModel(
        workOrder,
        repository: workRepository,
        agreementRepository: agreementRepository,
        vehicleRepository: vehicleRepository,
        driverRepository: driverRepository,
        businessProfileRepository: businessProfileRepository,
        partiesRepository: partiesRepository,
        moneyRepository: moneyRepository,
      );

      await model.init();

      expect(model.customer, customer);
      expect(model.agreement, agreement);
      expect(model.linkedInvoice, invoice);
      expect(model.linkedExpenses, hasLength(1));
      expect(model.linkedExpenses.first.id, 'e1');
      expect(model.totalSupplierPayable, 500.00);
    },
  );

  test('hasMoneyPermission checks user access pack', () {
    final workOrder = WorkOrder(
      id: 'work-1',
      number: 'WO-1039',
      customerId: 'c1',
      agreementId: 'a12',
      date: DateTime.now(),
      pickup: 'Monthly hire',
      destination: 'Sunday work',
    );

    when(() => authRepository.currentEmail).thenReturn('omar@almasar.ae');

    final model = WorkDetailViewModel(
      workOrder,
      repository: workRepository,
      agreementRepository: agreementRepository,
      vehicleRepository: vehicleRepository,
      driverRepository: driverRepository,
      businessProfileRepository: businessProfileRepository,
      partiesRepository: partiesRepository,
      moneyRepository: moneyRepository,
    );

    expect(model.hasMoneyPermission, isFalse);
  });

  test('complete failure surfaces the repository message', () async {
    final workOrder = WorkOrder(
      id: 'work-1',
      number: 'WO-1039',
      customerId: 'c1',
      agreementId: 'a12',
      date: DateTime.now(),
      pickup: 'Pickup',
      destination: 'Destination',
    );
    when(() => workRepository.complete('work-1')).thenAnswer(
      (_) async => const Failure(ValidationFailure('Complete failed')),
    );
    when(
      () => snackbarService.showCustomSnackBar(
        message: 'Complete failed',
        variant: SnackbarType.error,
      ),
    ).thenAnswer((_) => null);

    final model = WorkDetailViewModel(
      workOrder,
      repository: workRepository,
      agreementRepository: agreementRepository,
      vehicleRepository: vehicleRepository,
      driverRepository: driverRepository,
      businessProfileRepository: businessProfileRepository,
      partiesRepository: partiesRepository,
      moneyRepository: moneyRepository,
    );

    await model.complete();

    verify(
      () => snackbarService.showCustomSnackBar(
        message: 'Complete failed',
        variant: SnackbarType.error,
      ),
    ).called(1);
  });

  test('cancel failure surfaces the repository message', () async {
    final workOrder = WorkOrder(
      id: 'work-1',
      number: 'WO-1039',
      customerId: 'c1',
      agreementId: 'a12',
      date: DateTime.now(),
      pickup: 'Pickup',
      destination: 'Destination',
    );
    when(
      () => dialogService.showCustomDialog(
        variant: DialogType.confirm,
        title: 'Cancel work order?',
        description: 'Canceled work stays in history and cannot be billed.',
        mainButtonTitle: 'Cancel work order',
        secondaryButtonTitle: 'Keep work order',
      ),
    ).thenAnswer((_) async => DialogResponse(confirmed: true));
    when(() => workRepository.cancel('work-1')).thenAnswer(
      (_) async => const Failure(ValidationFailure('Cancel failed')),
    );
    when(
      () => snackbarService.showCustomSnackBar(
        message: 'Cancel failed',
        variant: SnackbarType.error,
      ),
    ).thenAnswer((_) => null);

    final model = WorkDetailViewModel(
      workOrder,
      repository: workRepository,
      agreementRepository: agreementRepository,
      vehicleRepository: vehicleRepository,
      driverRepository: driverRepository,
      businessProfileRepository: businessProfileRepository,
      partiesRepository: partiesRepository,
      moneyRepository: moneyRepository,
    );

    await model.cancel();

    verify(
      () => snackbarService.showCustomSnackBar(
        message: 'Cancel failed',
        variant: SnackbarType.error,
      ),
    ).called(1);
  });

  test('complete ignores a second call while the first is pending', () async {
    final workOrder = WorkOrder(
      id: 'work-1',
      number: 'WO-1',
      customerId: 'customer',
      agreementId: 'agreement',
      date: DateTime(2026, 7),
      pickup: 'A',
      destination: 'B',
    );
    final pending = Completer<Result<WorkOrder>>();
    when(
      () => workRepository.complete('work-1'),
    ).thenAnswer((_) => pending.future);
    when(
      () => snackbarService.showCustomSnackBar(
        message: 'Complete failed',
        variant: SnackbarType.error,
      ),
    ).thenAnswer((_) => null);
    final model = WorkDetailViewModel(
      workOrder,
      repository: workRepository,
      agreementRepository: agreementRepository,
      vehicleRepository: vehicleRepository,
      driverRepository: driverRepository,
      businessProfileRepository: businessProfileRepository,
      partiesRepository: partiesRepository,
      moneyRepository: moneyRepository,
    );

    final first = model.complete();
    await Future<void>.delayed(Duration.zero);
    final second = model.complete();

    verify(() => workRepository.complete('work-1')).called(1);
    pending.complete(const Failure(ValidationFailure('Complete failed')));
    await Future.wait([first, second]);
  });
}
