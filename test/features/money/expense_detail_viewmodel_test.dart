import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/driver.dart';
import 'package:fleetgo/core/models/expense.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/more/data/driver_repository.dart';
import 'package:fleetgo/features/more/data/vehicle_repository.dart';
import 'package:fleetgo/features/work/data/work_repository.dart';
import 'package:fleetgo/features/money/ui/expense_detail/expense_detail_viewmodel.dart';
import '../../helpers/stacked_service_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

class MockWorkRepository extends Mock implements WorkRepository {}

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockDriverRepository extends Mock implements DriverRepository {}

void main() {
  late MockWorkRepository workRepository;
  late MockVehicleRepository vehicleRepository;
  late MockDriverRepository driverRepository;
  late MockSnackbarService snackbarService;
  late MockNavigationService navigationService;

  setUp(() {
    workRepository = MockWorkRepository();
    vehicleRepository = MockVehicleRepository();
    driverRepository = MockDriverRepository();
    snackbarService = MockSnackbarService();
    navigationService = MockNavigationService();

    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<NavigationService>(navigationService);
  });

  tearDown(() {
    locator.reset();
  });

  test('init loads matching workOrder, vehicle, and driver links', () async {
    final expense = Expense(
      id: 'e1',
      date: DateTime.now(),
      category: ExpenseCategory.fuel,
      payee: 'ENOC',
      net: 100.00,
      workOrderId: 'work-1',
      vehicleId: 'v1',
      driverId: 'd1',
    );

    final workOrder = WorkOrder(
      id: 'work-1',
      number: 'WO-101',
      customerId: 'c1',
      agreementId: 'a1',
      date: DateTime.now(),
      pickup: 'A',
      destination: 'B',
    );
    final vehicle = Vehicle(
      id: 'v1',
      plateNumber: 'P123',
      label: 'Owned Truck',
      vehicleClass: VehicleClass.threeTon,
      ownership: VehicleOwnership.owned,
    );
    final driver = Driver(id: 'd1', name: 'Omar');

    when(
      () => workRepository.fetchAll(),
    ).thenAnswer((_) async => Success([workOrder]));
    when(
      () => vehicleRepository.fetchVehicles(),
    ).thenAnswer((_) async => Success([vehicle]));
    when(
      () => driverRepository.fetchDrivers(),
    ).thenAnswer((_) async => Success([driver]));

    final model = ExpenseDetailViewModel(
      expense,
      workRepository: workRepository,
      vehicleRepository: vehicleRepository,
      driverRepository: driverRepository,
    );

    await model.init();

    expect(model.workOrder, workOrder);
    expect(model.vehicle, vehicle);
    expect(model.driver, driver);
  });
}
