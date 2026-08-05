import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/driver.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/money/data/money_repository.dart';
import 'package:fleetgo/features/more/data/agreement_repository.dart';
import 'package:fleetgo/features/more/data/business_profile_repository.dart';
import 'package:fleetgo/features/more/data/driver_repository.dart';
import 'package:fleetgo/features/more/data/vehicle_repository.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/features/work/data/work_repository.dart';
import 'package:fleetgo/features/work/ui/work_detail/widgets/work_allocation_tile.dart';
import 'package:fleetgo/features/work/ui/work_detail/widgets/work_charge_tile.dart';
import 'package:fleetgo/features/work/ui/work_detail/work_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

class MockWorkRepository extends Mock implements WorkRepository {}

class MockAgreementRepository extends Mock implements AgreementRepository {}

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockDriverRepository extends Mock implements DriverRepository {}

class MockBusinessProfileRepository extends Mock
    implements BusinessProfileRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDialogService extends Mock implements DialogService {}

class MockNavigationService extends Mock implements NavigationService {}

class MockSnackbarService extends Mock implements SnackbarService {}

class TestWorkDetailViewModel extends WorkDetailViewModel {
  TestWorkDetailViewModel(super.work, this.allowMoney)
    : super(
        repository: MockWorkRepository(),
        agreementRepository: MockAgreementRepository(),
        vehicleRepository: MockVehicleRepository(),
        driverRepository: MockDriverRepository(),
        businessProfileRepository: MockBusinessProfileRepository(),
        partiesRepository: MockPartiesRepository(),
        moneyRepository: MockMoneyRepository(),
      );

  final bool allowMoney;

  @override
  bool get hasMoneyPermission => allowMoney;
}

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUp(() {
    locator.reset();
    locator.registerSingleton<AuthRepository>(MockAuthRepository());
    locator.registerSingleton<DialogService>(MockDialogService());
    locator.registerSingleton<NavigationService>(MockNavigationService());
    locator.registerSingleton<SnackbarService>(MockSnackbarService());
  });

  tearDown(locator.reset);

  testWidgets('WorkChargeTile renders a charge line', (tester) async {
    const line = ChargeLine(
      name: 'Fuel',
      quantity: 2,
      unit: 'litre',
      unitPrice: 10,
      discount: 1,
      vatRate: 5,
    );
    await tester.pumpWidget(app(const WorkChargeTile(line: line)));
    expect(find.text('Fuel'), findsOneWidget);
    expect(
      find.text('2 litre × 10.00 · Disc. 1.00 · VAT 5% · Net 19.00'),
      findsOneWidget,
    );
  });

  testWidgets('WorkAllocationTile shows owned and payable supplier rows', (
    tester,
  ) async {
    final work = WorkOrder(
      id: 'w1',
      number: 'WO-1',
      customerId: 'c1',
      date: DateTime(2026, 7, 18),
      pickup: 'A',
      destination: 'B',
    );
    final viewModel = TestWorkDetailViewModel(work, true)
      ..vehicles = [
        Vehicle(
          id: 'v1',
          plateNumber: 'P1',
          label: 'Owned truck',
          vehicleClass: VehicleClass.sevenTon,
          ownership: VehicleOwnership.owned,
        ),
        Vehicle(
          id: 'v2',
          plateNumber: 'P2',
          label: 'Supplier truck',
          vehicleClass: VehicleClass.sevenTon,
          ownership: VehicleOwnership.external,
        ),
      ]
      ..drivers = [Driver(id: 'd1', name: 'Driver One')];
    await tester.pumpWidget(
      app(
        Column(
          children: [
            WorkAllocationTile(
              allocation: const VehicleAllocation(
                vehicleId: 'v1',
                source: VehicleSource.owned,
              ),
              viewModel: viewModel,
            ),
            WorkAllocationTile(
              allocation: const VehicleAllocation(
                vehicleId: 'v2',
                driverId: 'd1',
                source: VehicleSource.supplier,
                supplierPayable: 250,
              ),
              viewModel: viewModel,
            ),
          ],
        ),
      ),
    );
    expect(find.text('Owned'), findsOneWidget);
    expect(find.text('External'), findsOneWidget);
    expect(find.text(Formatters.money(250)), findsOneWidget);
    expect(find.text('Assigned driver'), findsOneWidget);
    expect(find.text('Driver One'), findsOneWidget);
  });
}
