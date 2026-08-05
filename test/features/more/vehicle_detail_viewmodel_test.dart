import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/features/more/ui/vehicle_detail/vehicle_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

void main() {
  late MockVehicleRepository vehicleRepository;
  late MockPartiesRepository partiesRepository;
  late MockSnackbarService snackbarService;
  late MockNavigationService navigationService;
  late MockBottomSheetService bottomSheetService;

  setUp(() {
    vehicleRepository = MockVehicleRepository();
    partiesRepository = MockPartiesRepository();
    snackbarService = MockSnackbarService();
    navigationService = MockNavigationService();
    bottomSheetService = MockBottomSheetService();

    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<NavigationService>(navigationService);
    replaceTestRegistration<BottomSheetService>(bottomSheetService);
    if (locator.isRegistered<PartiesRepository>()) {
      locator.unregister<PartiesRepository>();
    }

    locator.registerSingleton<PartiesRepository>(partiesRepository);
  });

  tearDown(() {
    locator.reset();
  });

  test('init loads parties for supplier name lookup', () async {
    final vehicle = Vehicle(
      id: 'v1',
      plateNumber: 'P123',
      label: 'L123',
      vehicleClass: VehicleClass.threeTon,
      ownership: VehicleOwnership.owned,
    );
    final party = Party(
      id: 's1',
      name: 'Khalid Transport',
      type: PartyType.supplier,
    );

    when(
      () => partiesRepository.fetchAll(),
    ).thenAnswer((_) async => Success([party]));

    final model = VehicleDetailViewModel(
      vehicle,
      repository: vehicleRepository,
    );

    await model.init();

    expect(model.parties, hasLength(1));
    expect(model.getSupplierName('s1'), 'Khalid Transport');
    expect(
      model.getSupplierName('non-existent'),
      'Unknown Supplier (non-existent)',
    );
    expect(model.getSupplierName(null), '—');
  });

  test('editVehicle shows bottom sheet and updates vehicle info', () async {
    final vehicle = Vehicle(
      id: 'v1',
      plateNumber: 'P123',
      label: 'L123',
      vehicleClass: VehicleClass.threeTon,
      ownership: VehicleOwnership.owned,
    );
    final updatedVehicle = Vehicle(
      id: 'v1',
      plateNumber: 'P123-Updated',
      label: 'L123-Updated',
      vehicleClass: VehicleClass.threeTon,
      ownership: VehicleOwnership.owned,
    );

    when(
      () => bottomSheetService.showCustomSheet<Vehicle, Vehicle>(
        variant: any(named: 'variant'),
        data: any(named: 'data'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer(
      (_) async => SheetResponse(confirmed: true, data: updatedVehicle),
    );

    when(
      () => vehicleRepository.addVehicle(updatedVehicle),
    ).thenAnswer((_) async => Success(updatedVehicle));
    when(
      () => partiesRepository.fetchAll(),
    ).thenAnswer((_) async => const Success(<Party>[]));

    final model = VehicleDetailViewModel(
      vehicle,
      repository: vehicleRepository,
    );

    await model.editVehicle();

    expect(model.vehicle.label, 'L123-Updated');
  });

  test('archiveVehicle calls repository and navigates back', () async {
    final vehicle = Vehicle(
      id: 'v1',
      plateNumber: 'P123',
      label: 'L123',
      vehicleClass: VehicleClass.threeTon,
      ownership: VehicleOwnership.owned,
    );

    when(
      () => vehicleRepository.archiveVehicle('v1'),
    ).thenAnswer((_) async => const Success(null));
    when(() => navigationService.back()).thenReturn(true);

    final model = VehicleDetailViewModel(
      vehicle,
      repository: vehicleRepository,
    );

    await model.archiveVehicle();

    verify(() => vehicleRepository.archiveVehicle('v1')).called(1);
    verify(() => navigationService.back()).called(1);
  });
}
