import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:cuboid_flutter_template/core/models/route_rate.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/more/data/agreement_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/driver_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/route_rate_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/features/more/ui/agreements/agreements_viewmodel.dart';
import 'package:cuboid_flutter_template/features/more/ui/drivers/drivers_viewmodel.dart';
import 'package:cuboid_flutter_template/features/more/ui/route_rates/route_rates_viewmodel.dart';
import 'package:cuboid_flutter_template/features/more/ui/vehicles/vehicles_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockDriverRepository extends Mock implements DriverRepository {}

class MockAgreementRepository extends Mock implements AgreementRepository {}

class MockRouteRateRepository extends Mock implements RouteRateRepository {}

PaginatedResult<T> page<T>(List<T> items) => PaginatedResult(
  items: items,
  pageNumber: 1,
  pageSize: 50,
  totalRecords: items.length,
);

void main() {
  late MockVehicleRepository vehicleRepository;
  late MockDriverRepository driverRepository;
  late MockAgreementRepository agreementRepository;
  late MockRouteRateRepository routeRateRepository;
  late MockBottomSheetService bottomSheetService;
  late MockSnackbarService snackbarService;
  late MockNavigationService navigationService;

  setUp(() {
    vehicleRepository = MockVehicleRepository();
    driverRepository = MockDriverRepository();
    agreementRepository = MockAgreementRepository();
    routeRateRepository = MockRouteRateRepository();
    bottomSheetService = MockBottomSheetService();
    snackbarService = MockSnackbarService();
    navigationService = MockNavigationService();

    if (locator.isRegistered<VehicleRepository>()) {
      locator.unregister<VehicleRepository>();
    }
    if (locator.isRegistered<DriverRepository>()) {
      locator.unregister<DriverRepository>();
    }
    if (locator.isRegistered<AgreementRepository>()) {
      locator.unregister<AgreementRepository>();
    }
    if (locator.isRegistered<RouteRateRepository>()) {
      locator.unregister<RouteRateRepository>();
    }
    replaceTestRegistration<BottomSheetService>(bottomSheetService);
    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<NavigationService>(navigationService);

    locator.registerSingleton<VehicleRepository>(vehicleRepository);
    locator.registerSingleton<DriverRepository>(driverRepository);
    locator.registerSingleton<AgreementRepository>(agreementRepository);
    locator.registerSingleton<RouteRateRepository>(routeRateRepository);
  });

  tearDown(() {
    locator.reset();
  });

  group('VehiclesViewModel Tests', () {
    test('init loads vehicles', () async {
      final vehicles = [
        Vehicle(
          id: 'v1',
          plateNumber: 'P1',
          label: 'L1',
          vehicleClass: VehicleClass.threeTon,
          ownership: VehicleOwnership.owned,
        ),
      ];
      when(
        () => vehicleRepository.fetchVehiclesPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).thenAnswer((_) async => Success(page(vehicles)));

      final model = VehiclesViewModel();
      await model.init();

      expect(model.pagination.items, hasLength(1));
      expect(model.pagination.items.first.id, 'v1');
    });

    test('addVehicle shows sheet and adds to repository', () async {
      final vehicle = Vehicle(
        id: 'v1',
        plateNumber: 'P1',
        label: 'L1',
        vehicleClass: VehicleClass.threeTon,
        ownership: VehicleOwnership.owned,
      );
      when(
        () => bottomSheetService.showCustomSheet<Vehicle, dynamic>(
          variant: any(named: 'variant'),
          isScrollControlled: any(named: 'isScrollControlled'),
        ),
      ).thenAnswer((_) async => SheetResponse(confirmed: true, data: vehicle));

      when(
        () => vehicleRepository.addVehicle(vehicle),
      ).thenAnswer((_) async => Success(vehicle));
      when(
        () => vehicleRepository.fetchVehiclesPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).thenAnswer((_) async => Success(page([vehicle])));

      final model = VehiclesViewModel();
      await model.addVehicle();

      verify(() => vehicleRepository.addVehicle(vehicle)).called(1);
      verify(
        () => vehicleRepository.fetchVehiclesPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).called(1);
    });

    test('init exposes page failure', () async {
      when(
        () => vehicleRepository.fetchVehiclesPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).thenAnswer((_) async => const Failure(ServerFailure('failed')));

      final model = VehiclesViewModel();
      await model.init();

      expect(model.pagination.error, 'failed');
    });
  });

  group('DriversViewModel Tests', () {
    test('init loads drivers', () async {
      final drivers = [Driver(id: 'd1', name: 'Omar')];
      when(
        () => driverRepository.fetchDriversPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).thenAnswer((_) async => Success(page(drivers)));

      final model = DriversViewModel();
      await model.init();

      expect(model.pagination.items, hasLength(1));
      expect(model.pagination.items.first.id, 'd1');
    });

    test('addDriver shows sheet and adds to repository', () async {
      final driver = Driver(id: 'd1', name: 'Omar');
      when(
        () => bottomSheetService.showCustomSheet<Driver, dynamic>(
          variant: any(named: 'variant'),
          isScrollControlled: any(named: 'isScrollControlled'),
        ),
      ).thenAnswer((_) async => SheetResponse(confirmed: true, data: driver));

      when(
        () => driverRepository.addDriver(driver),
      ).thenAnswer((_) async => Success(driver));
      when(
        () => driverRepository.fetchDriversPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).thenAnswer((_) async => Success(page([driver])));

      final model = DriversViewModel();
      await model.addDriver();

      verify(() => driverRepository.addDriver(driver)).called(1);
      verify(
        () => driverRepository.fetchDriversPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).called(1);
    });
  });

  group('AgreementsViewModel Tests', () {
    test('init loads agreements', () async {
      final agreements = [
        Agreement(
          id: 'a1',
          reference: 'R1',
          name: 'N1',
          customerId: 'c1',
          rateModel: RateModel.perTrip,
        ),
      ];
      when(
        () => agreementRepository.fetchAgreementsPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).thenAnswer((_) async => Success(page(agreements)));

      final model = AgreementsViewModel();
      await model.init();

      expect(model.pagination.items, hasLength(1));
      expect(model.pagination.items.first.id, 'a1');
    });

    test('addAgreement shows sheet and adds to repository', () async {
      final agreement = Agreement(
        id: 'a1',
        reference: 'R1',
        name: 'N1',
        customerId: 'c1',
        rateModel: RateModel.perTrip,
      );
      when(
        () => bottomSheetService.showCustomSheet<Agreement, dynamic>(
          variant: any(named: 'variant'),
          isScrollControlled: any(named: 'isScrollControlled'),
        ),
      ).thenAnswer(
        (_) async => SheetResponse(confirmed: true, data: agreement),
      );

      when(
        () => agreementRepository.addAgreement(agreement),
      ).thenAnswer((_) async => Success(agreement));
      when(
        () => agreementRepository.fetchAgreementsPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).thenAnswer((_) async => Success(page([agreement])));

      final model = AgreementsViewModel();
      await model.addAgreement();

      verify(() => agreementRepository.addAgreement(agreement)).called(1);
      verify(
        () => agreementRepository.fetchAgreementsPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).called(1);
    });
  });

  group('RouteRatesViewModel Tests', () {
    test('init loads route rates', () async {
      final routes = [
        RouteRate(
          id: 'r1',
          appliesTo: 'All',
          pickup: 'A',
          destination: 'B',
          vehicleClass: VehicleClass.threeTon,
          rate: 500.00,
        ),
      ];
      when(
        () => routeRateRepository.fetchRouteRatesPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).thenAnswer((_) async => Success(page(routes)));

      final model = RouteRatesViewModel();
      await model.init();

      expect(model.pagination.items, hasLength(1));
      expect(model.pagination.items.first.id, 'r1');
    });

    test('addRouteRate shows sheet and adds to repository', () async {
      final route = RouteRate(
        id: 'r1',
        appliesTo: 'All',
        pickup: 'A',
        destination: 'B',
        vehicleClass: VehicleClass.threeTon,
        rate: 500.00,
      );
      when(
        () => bottomSheetService.showCustomSheet<RouteRate, dynamic>(
          variant: any(named: 'variant'),
          isScrollControlled: any(named: 'isScrollControlled'),
        ),
      ).thenAnswer((_) async => SheetResponse(confirmed: true, data: route));

      when(
        () => routeRateRepository.addRouteRate(route),
      ).thenAnswer((_) async => Success(route));
      when(
        () => routeRateRepository.fetchRouteRatesPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).thenAnswer((_) async => Success(page([route])));

      final model = RouteRatesViewModel();
      await model.addRouteRate();

      verify(() => routeRateRepository.addRouteRate(route)).called(1);
      verify(
        () => routeRateRepository.fetchRouteRatesPage(
          pageNumber: 1,
          pageSize: 50,
          search: null,
        ),
      ).called(1);
    });
  });
}
