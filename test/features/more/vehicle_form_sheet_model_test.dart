import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/vehicle_form/vehicle_form_sheet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

class MockPartiesRepository extends Mock implements PartiesRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockPartiesRepository partiesRepository;

  setUp(() {
    partiesRepository = MockPartiesRepository();

    if (locator.isRegistered<PartiesRepository>()) {
      locator.unregister<PartiesRepository>();
    }
    locator.registerSingleton<PartiesRepository>(partiesRepository);
  });

  tearDown(() {
    locator.reset();
  });

  test('init hydrates selected supplier', () async {
    final supplier = Party(
      id: 's1',
      name: 'Supplier A',
      type: PartyType.supplier,
    );
    final initial = Vehicle(
      id: 'v1',
      plateNumber: 'DXB A 123',
      label: 'Truck',
      vehicleClass: VehicleClass.threeTon,
      ownership: VehicleOwnership.external,
      supplierId: 's1',
    );
    when(
      () => partiesRepository.fetchById('s1'),
    ).thenAnswer((_) async => Success(supplier));

    final model = VehicleFormSheetModel(
      completer: (_) {},
      request: SheetRequest(data: initial),
    );

    await model.init();

    expect(model.selectedSupplier, supplier);
  });

  test('init exposes supplier hydration failures', () async {
    final initial = Vehicle(
      id: 'v1',
      plateNumber: 'DXB A 123',
      label: 'Truck',
      vehicleClass: VehicleClass.threeTon,
      ownership: VehicleOwnership.external,
      supplierId: 's1',
    );
    when(
      () => partiesRepository.fetchById('s1'),
    ).thenAnswer((_) async => const Failure(ValidationFailure('load failed')));

    final model = VehicleFormSheetModel(
      completer: (_) {},
      request: SheetRequest(data: initial),
    );
    await model.init();

    expect(model.errorMessage, 'load failed');
    expect(model.isEditing, isTrue);
    model.dispose();
  });

  test('selection updates ownership, class, and supplier', () {
    final supplier = Party(
      id: 's1',
      name: 'Supplier A',
      type: PartyType.supplier,
    );
    final model = VehicleFormSheetModel(
      completer: (_) {},
      request: SheetRequest(),
    );

    model.selectOwnership([VehicleOwnership.external]);
    model.selectSupplier(supplier);
    model.selectVehicleClass(VehicleClass.sevenTon);
    expect(model.ownership, VehicleOwnership.external);
    expect(model.selectedSupplier?.id, 's1');
    expect(model.vehicleClass, VehicleClass.sevenTon);

    model.selectOwnership([VehicleOwnership.owned]);
    expect(model.selectedSupplier, isNull);
    model.selectVehicleClass(null);
    expect(model.vehicleClass, VehicleClass.sevenTon);
    model.dispose();
  });

  test('submit fails validation on empty plate number', () async {
    Vehicle? completed;
    final model = VehicleFormSheetModel(
      completer: (response) => completed = response.data as Vehicle?,
      request: SheetRequest(),
    );

    model.plateNumberController.text = '';
    model.submit();

    expect(completed, isNull);
  });

  test(
    'submit fails validation if external vehicle is missing supplier',
    () async {
      Vehicle? completed;
      final model = VehicleFormSheetModel(
        completer: (response) => completed = response.data as Vehicle?,
        request: SheetRequest(),
      );

      model.plateNumberController.text = 'DXB A 123';
      model.ownership = VehicleOwnership.external;
      model.selectSupplier(null);

      model.submit();

      expect(completed, isNull);
    },
  );

  test('submit rejects a malformed vehicle year', () {
    Vehicle? completed;
    final model = VehicleFormSheetModel(
      completer: (response) => completed = response.data as Vehicle?,
      request: SheetRequest(),
    );

    model.plateNumberController.text = 'DXB A 123';
    model.yearController.text = 'twenty twenty';
    model.submit();

    expect(completed, isNull);
  });

  test('submit succeeds and returns a Vehicle model', () async {
    Vehicle? completedVehicle;
    final model = VehicleFormSheetModel(
      completer: (response) {
        completedVehicle = response.data as Vehicle?;
      },
      request: SheetRequest(),
    );

    model.plateNumberController.text = 'DXB A 123';
    model.ownership = VehicleOwnership.owned;
    model.vehicleClass = VehicleClass.threeTon;
    model.submit();

    expect(completedVehicle, isNotNull);
    expect(completedVehicle!.plateNumber, 'DXB A 123');
    expect(completedVehicle!.ownership, VehicleOwnership.owned);
    expect(completedVehicle!.vehicleClass, VehicleClass.threeTon);
  });

  test('edit mode prefills fields and preserves vehicle id', () {
    final registrationExpiry = DateTime(2026, 8, 1);
    final insuranceExpiry = DateTime(2026, 9, 1);
    final inspectionExpiry = DateTime(2026, 10, 1);
    final initial = Vehicle(
      id: 'v1',
      plateNumber: 'DXB A 123',
      label: 'Truck',
      vehicleClass: VehicleClass.sevenTon,
      ownership: VehicleOwnership.external,
      supplierId: 's1',
      make: 'Make',
      model: 'Model',
      year: 2024,
      registrationExpiry: registrationExpiry,
      insuranceExpiry: insuranceExpiry,
      inspectionExpiry: inspectionExpiry,
      notes: 'note',
    );
    Vehicle? saved;
    final model = VehicleFormSheetModel(
      completer: (response) => saved = response.data as Vehicle?,
      request: SheetRequest(data: initial),
    );

    expect(model.isEditing, isTrue);
    expect(model.labelController.text, 'Truck');
    expect(model.makeController.text, 'Make');
    expect(model.modelController.text, 'Model');
    expect(model.yearController.text, '2024');
    expect(model.registrationExpiry, registrationExpiry);
    expect(model.insuranceExpiry, insuranceExpiry);
    expect(model.inspectionExpiry, inspectionExpiry);

    model.selectSupplier(
      Party(id: 's1', name: 'Supplier A', type: PartyType.supplier),
    );
    model.submit();
    expect(saved!.id, 'v1');
    expect(saved!.label, 'Truck');
    expect(saved!.year, 2024);
    expect(saved!.notes, 'note');
    model.dispose();
  });
}
