import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/core/models/expense.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/more/data/driver_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/add_expense/add_expense_sheet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockDriverRepository extends Mock implements DriverRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockVehicleRepository vehicleRepository;
  late MockDriverRepository driverRepository;

  setUp(() {
    vehicleRepository = MockVehicleRepository();
    driverRepository = MockDriverRepository();

    if (locator.isRegistered<VehicleRepository>()) {
      locator.unregister<VehicleRepository>();
    }
    if (locator.isRegistered<DriverRepository>()) {
      locator.unregister<DriverRepository>();
    }
    locator.registerSingleton<VehicleRepository>(vehicleRepository);
    locator.registerSingleton<DriverRepository>(driverRepository);
  });

  tearDown(() {
    locator.reset();
  });

  test('availableCategories excludes supplierPayout', () {
    final model = AddExpenseSheetModel(completer: (_) {});
    expect(model.availableCategories, contains(ExpenseCategory.fuel));
    expect(model.availableCategories, contains(ExpenseCategory.driverPay));
  });

  test('isVehicleExpense and isDriverExpense flags are correctly set', () {
    final model = AddExpenseSheetModel(completer: (_) {});

    model.category = ExpenseCategory.fuel;
    expect(model.isVehicleExpense, isTrue);
    expect(model.isDriverExpense, isFalse);

    model.category = ExpenseCategory.driverPay;
    expect(model.isVehicleExpense, isFalse);
    expect(model.isDriverExpense, isTrue);

    model.category = ExpenseCategory.other;
    expect(model.isVehicleExpense, isFalse);
    expect(model.isDriverExpense, isFalse);
  });

  test('filteredVehicles filters by plate or label', () async {
    final vehicles = [
      Vehicle(
        id: 'v1',
        plateNumber: 'DXB A 12345',
        label: 'Truck A',
        ownership: VehicleOwnership.owned,
        vehicleClass: VehicleClass.sevenTon,
      ),
      Vehicle(
        id: 'v2',
        plateNumber: 'SHJ B 54321',
        label: 'Van B',
        ownership: VehicleOwnership.owned,
        vehicleClass: VehicleClass.sevenTon,
      ),
    ];

    when(
      () => vehicleRepository.fetchVehicles(),
    ).thenAnswer((_) async => Success(vehicles));
    when(
      () => driverRepository.fetchDrivers(),
    ).thenAnswer((_) async => const Success([]));

    final model = AddExpenseSheetModel(completer: (_) {});
    await model.init();

    expect(model.filteredVehicles, hasLength(2));

    model.setVehicleSearchQuery('DXB');
    expect(model.filteredVehicles, hasLength(1));
    expect(model.filteredVehicles.first.id, 'v1');

    model.setVehicleSearchQuery('Van');
    expect(model.filteredVehicles, hasLength(1));
    expect(model.filteredVehicles.first.id, 'v2');
  });

  test(
    'submit fails validation if required link is missing, succeeds when provided',
    () async {
      final vehicles = [
        Vehicle(
          id: 'v1',
          plateNumber: 'DXB A 12345',
          label: 'Truck A',
          ownership: VehicleOwnership.owned,
          vehicleClass: VehicleClass.sevenTon,
        ),
      ];
      final drivers = [
        Driver(id: 'd1', name: 'Rashid Ali', phone: '050', licenceNumber: 'L1'),
      ];

      when(
        () => vehicleRepository.fetchVehicles(),
      ).thenAnswer((_) async => Success(vehicles));
      when(
        () => driverRepository.fetchDrivers(),
      ).thenAnswer((_) async => Success(drivers));

      Expense? savedExpense;
      final model = AddExpenseSheetModel(
        completer: (response) {
          savedExpense = response.data as Expense;
        },
      );

      await model.init();

      // 1. Vehicle Expense: Missing vehicleId
      model.category = ExpenseCategory.fuel;
      model.payeeController.text = 'ENOC';
      model.amountController.text = '150.00';
      model.submit();
      expect(savedExpense, isNull); // validation failed

      // Select vehicle and re-submit
      model.selectVehicle(vehicles.first);
      model.submit();
      expect(savedExpense, isNotNull);
      expect(savedExpense!.id, isEmpty);
      expect(savedExpense!.vehicleId, 'v1');
      expect(savedExpense!.driverId, isNull);

      // 2. Driver Expense: Missing driverId
      savedExpense = null;
      model.category = ExpenseCategory.driverPay;
      model.submit();
      expect(savedExpense, isNull); // validation failed

      // Select driver and re-submit
      model.selectDriver(drivers.first);
      model.submit();
      expect(savedExpense, isNotNull);
      expect(savedExpense!.vehicleId, isNull);
      expect(savedExpense!.driverId, 'd1');
    },
  );

  test('submit surfaces malformed, non-positive, and missing payee values', () {
    Expense? saved;
    final model = AddExpenseSheetModel(
      completer: (response) => saved = response.data as Expense?,
    )..category = ExpenseCategory.other;

    model.amountController.text = 'invalid';
    model.submit();
    expect(saved, isNull);

    model.amountController.text = '0';
    model.submit();
    expect(saved, isNull);

    model.amountController.text = '10';
    model.submit();
    expect(saved, isNull);
  });
}
