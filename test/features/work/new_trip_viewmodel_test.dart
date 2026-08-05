import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/route_rate.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/more/data/agreement_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/driver_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/route_rate_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/features/shell/shell_service.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/new_trip_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockWorkRepository extends Mock implements WorkRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockDriverRepository extends Mock implements DriverRepository {}

class MockAgreementRepository extends Mock implements AgreementRepository {}

class MockRouteRateRepository extends Mock implements RouteRateRepository {}

class FakeWorkOrder extends Fake implements WorkOrder {}

class FakeAgreement extends Fake implements Agreement {}

class FakeRouteRate extends Fake implements RouteRate {}

void main() {
  late MockNavigationService navigationService;
  late MockSnackbarService snackbarService;
  late MockBottomSheetService bottomSheetService;
  late MockDialogService dialogService;
  late MockWorkRepository workRepository;
  late MockPartiesRepository partiesRepository;
  late MockVehicleRepository vehicleRepository;
  late MockDriverRepository driverRepository;
  late MockAgreementRepository agreementRepository;
  late MockRouteRateRepository routeRateRepository;

  setUpAll(() {
    registerFallbackValue(FakeWorkOrder());
    registerFallbackValue(FakeAgreement());
    registerFallbackValue(FakeRouteRate());
  });

  setUp(() {
    navigationService = MockNavigationService();
    snackbarService = MockSnackbarService();
    bottomSheetService = MockBottomSheetService();
    dialogService = MockDialogService();
    workRepository = MockWorkRepository();
    partiesRepository = MockPartiesRepository();
    vehicleRepository = MockVehicleRepository();
    driverRepository = MockDriverRepository();
    agreementRepository = MockAgreementRepository();
    routeRateRepository = MockRouteRateRepository();

    replaceTestRegistration<NavigationService>(navigationService);
    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<BottomSheetService>(bottomSheetService);
    replaceTestRegistration<DialogService>(dialogService);
    replaceTestRegistration<ShellService>(ShellService());
    if (locator.isRegistered<WorkRepository>()) {
      locator.unregister<WorkRepository>();
    }
    if (locator.isRegistered<PartiesRepository>()) {
      locator.unregister<PartiesRepository>();
    }
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

    locator.registerSingleton<WorkRepository>(workRepository);
    locator.registerSingleton<PartiesRepository>(partiesRepository);
    locator.registerSingleton<VehicleRepository>(vehicleRepository);
    locator.registerSingleton<DriverRepository>(driverRepository);
    locator.registerSingleton<AgreementRepository>(agreementRepository);
    locator.registerSingleton<RouteRateRepository>(routeRateRepository);
  });

  tearDown(() {
    locator.reset();
  });

  group('NewTripViewModel -', () {
    test('init does not eagerly fetch master lists', () async {
      final viewModel = NewTripViewModel(
        workRepository: workRepository,
        partiesRepository: partiesRepository,
        vehicleRepository: vehicleRepository,
        driverRepository: driverRepository,
        agreementRepository: agreementRepository,
        routeRateRepository: routeRateRepository,
      );

      await viewModel.init();

      verifyNever(() => partiesRepository.fetchAll());
      verifyNever(() => vehicleRepository.fetchVehicles());
      verifyNever(() => driverRepository.fetchDrivers());
      verifyNever(() => agreementRepository.fetchAgreements());
      verifyNever(() => routeRateRepository.fetchRouteRates());
    });

    test('step 1 validation triggers snackbar on blank input', () async {
      when(
        () => partiesRepository.fetchAll(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => vehicleRepository.fetchVehicles(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => driverRepository.fetchDrivers(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => agreementRepository.fetchAgreements(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => routeRateRepository.fetchRouteRates(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => snackbarService.showCustomSnackBar(
          message: any(named: 'message'),
          variant: any(named: 'variant'),
        ),
      ).thenAnswer((_) => null);

      final viewModel = NewTripViewModel(
        workRepository: workRepository,
        partiesRepository: partiesRepository,
        vehicleRepository: vehicleRepository,
        driverRepository: driverRepository,
        agreementRepository: agreementRepository,
        routeRateRepository: routeRateRepository,
      );

      await viewModel.init();

      // Step 1: fields are blank initially, customerId is null
      await viewModel.next();
      expect(viewModel.step, equals(1));
      verify(
        () => snackbarService.showCustomSnackBar(
          message: 'Please select a customer',
          variant: SnackbarType.warning,
        ),
      ).called(1);

      viewModel.customerId = 'c1';
      await viewModel.next();
      expect(viewModel.step, equals(1));
      verify(
        () => snackbarService.showCustomSnackBar(
          message: 'Please specify the pickup place',
          variant: SnackbarType.warning,
        ),
      ).called(1);

      viewModel.pickup.text = 'Jebel Ali';
      await viewModel.next();
      expect(viewModel.step, equals(1));
      verify(
        () => snackbarService.showCustomSnackBar(
          message: 'Please specify the destination',
          variant: SnackbarType.warning,
        ),
      ).called(1);

      viewModel.destination.text = 'Ajman';
      await viewModel.next();
      expect(viewModel.step, equals(2)); // Moves to step 2!
    });

    test(
      'step 2 validation triggers snackbar on missing vehicle or driver',
      () async {
        when(
          () => partiesRepository.fetchAll(),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => vehicleRepository.fetchVehicles(),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => driverRepository.fetchDrivers(),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => agreementRepository.fetchAgreements(),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => routeRateRepository.fetchRouteRates(),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => snackbarService.showCustomSnackBar(
            message: any(named: 'message'),
            variant: any(named: 'variant'),
          ),
        ).thenAnswer((_) => null);

        final viewModel = NewTripViewModel(
          workRepository: workRepository,
          partiesRepository: partiesRepository,
          vehicleRepository: vehicleRepository,
          driverRepository: driverRepository,
          agreementRepository: agreementRepository,
          routeRateRepository: routeRateRepository,
        );

        await viewModel.init();
        viewModel.step = 2;
        final vehicle = Vehicle(
          id: 'v1',
          plateNumber: 'A-1234',
          label: 'A-1234',
          vehicleClass: VehicleClass.sevenTon,
          ownership: VehicleOwnership.owned,
        );
        final driver = Driver(id: 'd1', name: 'Omar');

        // No vehicle or driver selected
        await viewModel.next();
        expect(viewModel.step, equals(2));
        verify(
          () => snackbarService.showCustomSnackBar(
            message: 'Please select a vehicle',
            variant: SnackbarType.warning,
          ),
        ).called(1);

        viewModel.selectVehicle(vehicle);
        await viewModel.next();
        expect(viewModel.step, equals(2));
        verify(
          () => snackbarService.showCustomSnackBar(
            message: 'Please select a driver',
            variant: SnackbarType.warning,
          ),
        ).called(1);

        viewModel.selectDriver(driver);
        await viewModel.next();
        expect(viewModel.step, equals(3)); // Moves to step 3!
      },
    );

    test(
      'next saves work order with no agreement when customer has none',
      () async {
        final customer = Party(
          id: 'c1',
          name: 'Gulf Star',
          type: PartyType.customer,
        );
        final driver = Driver(id: 'd1', name: 'Omar', phone: '123456');
        final vehicle = Vehicle(
          id: 'v1',
          plateNumber: 'A-1234',
          label: 'A-1234',
          vehicleClass: VehicleClass.sevenTon,
          ownership: VehicleOwnership.owned,
        );

        when(
          () => partiesRepository.fetchAll(),
        ).thenAnswer((_) async => Success([customer]));
        when(
          () => vehicleRepository.fetchVehicles(),
        ).thenAnswer((_) async => Success([vehicle]));
        when(
          () => driverRepository.fetchDrivers(),
        ).thenAnswer((_) async => Success([driver]));
        when(() => agreementRepository.fetchAgreements()).thenAnswer(
          (_) async => const Success([]), // No agreement for this customer.
        );
        when(
          () => routeRateRepository.fetchRouteRates(),
        ).thenAnswer((_) async => const Success([]));
        when(() => workRepository.create(any())).thenAnswer(
          (_) async => Success(
            WorkOrder(
              id: 'work-1',
              number: 'WO-001',
              customerId: 'c1',
              date: DateTime.now(),
              pickup: 'Jebel Ali',
              destination: 'Ajman',
              allocations: [],
              chargeLines: [],
            ),
          ),
        );
        when(
          () => snackbarService.showCustomSnackBar(
            message: any(named: 'message'),
            variant: any(named: 'variant'),
          ),
        ).thenAnswer((_) => null);
        when(() => navigationService.back()).thenReturn(true);
        when(
          () => dialogService.showCustomDialog(
            title: any(named: 'title'),
            description: any(named: 'description'),
          ),
        ).thenAnswer((_) async => null);

        final viewModel = NewTripViewModel(
          workRepository: workRepository,
          partiesRepository: partiesRepository,
          vehicleRepository: vehicleRepository,
          driverRepository: driverRepository,
          agreementRepository: agreementRepository,
          routeRateRepository: routeRateRepository,
        );

        await viewModel.init();
        viewModel.step = 3;
        viewModel.customerId = 'c1';
        viewModel.selectVehicle(vehicle);
        viewModel.selectDriver(driver);
        viewModel.pickup.text = 'Jebel Ali';
        viewModel.destination.text = 'Ajman';
        viewModel.rate.text = '1200';

        await viewModel.next();

        verifyNever(() => agreementRepository.addAgreement(any()));
        final captured = verify(
          () => workRepository.create(captureAny()),
        ).captured;
        expect((captured.single as WorkOrder).agreementId, isNull);
        verify(
          () => snackbarService.showCustomSnackBar(
            message: 'WO-001 created',
            variant: SnackbarType.success,
          ),
        ).called(1);
        verify(() => navigationService.back()).called(1);
      },
    );

    test('next saves a custom route after dialog confirmation', () async {
      final customer = Party(
        id: 'c1',
        name: 'Gulf Star',
        type: PartyType.customer,
      );
      final driver = Driver(id: 'd1', name: 'Omar', phone: '123456');
      final vehicle = Vehicle(
        id: 'v1',
        plateNumber: 'A-1234',
        label: 'A-1234',
        vehicleClass: VehicleClass.sevenTon,
        ownership: VehicleOwnership.owned,
      );

      final agreement = Agreement(
        id: 'a12',
        reference: 'AGR-012',
        name: 'Gulf Star monthly hire',
        customerId: 'c1',
        rateModel: RateModel.perTrip,
      );

      final savedRoute = RouteRate(
        id: 'route-1',
        appliesTo: 'All customers',
        pickup: 'Custom Pickup',
        destination: 'Custom Dest',
        vehicleClass: VehicleClass.sevenTon,
        rate: 1200.00,
        defaultExtras: {},
      );

      when(
        () => partiesRepository.fetchAll(),
      ).thenAnswer((_) async => Success([customer]));
      when(
        () => vehicleRepository.fetchVehicles(),
      ).thenAnswer((_) async => Success([vehicle]));
      when(
        () => driverRepository.fetchDrivers(),
      ).thenAnswer((_) async => Success([driver]));
      when(
        () => agreementRepository.fetchAgreements(),
      ).thenAnswer((_) async => Success([agreement]));
      when(
        () => routeRateRepository.fetchRouteRates(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => routeRateRepository.addRouteRate(any()),
      ).thenAnswer((_) async => Success(savedRoute));
      when(() => workRepository.create(any())).thenAnswer(
        (_) async => Success(
          WorkOrder(
            id: 'work-1',
            number: 'WO-001',
            customerId: 'c1',
            agreementId: 'a12',
            date: DateTime.now(),
            pickup: 'Custom Pickup',
            destination: 'Custom Dest',
            allocations: [],
            chargeLines: [],
          ),
        ),
      );
      when(
        () => snackbarService.showCustomSnackBar(
          message: any(named: 'message'),
          variant: any(named: 'variant'),
        ),
      ).thenAnswer((_) => null);
      when(() => navigationService.back()).thenReturn(true);
      when(
        () => dialogService.showCustomDialog(
          title: any(named: 'title'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => DialogResponse(confirmed: true));

      final viewModel = NewTripViewModel(
        workRepository: workRepository,
        partiesRepository: partiesRepository,
        vehicleRepository: vehicleRepository,
        driverRepository: driverRepository,
        agreementRepository: agreementRepository,
        routeRateRepository: routeRateRepository,
      );

      await viewModel.init();
      viewModel.step = 3;
      viewModel.customerId = 'c1';
      viewModel.selectVehicle(vehicle);
      viewModel.selectDriver(driver);
      viewModel.pickup.text = 'Custom Pickup';
      viewModel.destination.text = 'Custom Dest';
      viewModel.rate.text = '1200';

      // routeId is null
      viewModel.routeId = null;
      await viewModel.next();

      verify(() => routeRateRepository.addRouteRate(any())).called(1);
      verify(() => workRepository.create(any())).called(1);
      verify(
        () => snackbarService.showCustomSnackBar(
          message: 'WO-001 created',
          variant: SnackbarType.success,
        ),
      ).called(1);
      verify(() => navigationService.back()).called(1);
    });

    test(
      'external allocation has no guessed payable and uses empty identifiers',
      () async {
        final customer = Party(
          id: 'c1',
          name: 'Gulf Star',
          type: PartyType.customer,
        );
        final driver = Driver(id: 'd1', name: 'Omar', phone: '123456');
        final vehicle = Vehicle(
          id: 'v1',
          plateNumber: 'A-1234',
          label: 'A-1234',
          vehicleClass: VehicleClass.sevenTon,
          ownership: VehicleOwnership.external,
          supplierId: 'supplier-1',
        );
        final agreement = Agreement(
          id: 'a12',
          reference: 'AGR-012',
          name: 'Gulf Star agreement',
          customerId: 'c1',
          rateModel: RateModel.perTrip,
        );
        WorkOrder? created;

        when(
          () => partiesRepository.fetchAll(),
        ).thenAnswer((_) async => Success([customer]));
        when(
          () => vehicleRepository.fetchVehicles(),
        ).thenAnswer((_) async => Success([vehicle]));
        when(
          () => driverRepository.fetchDrivers(),
        ).thenAnswer((_) async => Success([driver]));
        when(
          () => agreementRepository.fetchAgreements(),
        ).thenAnswer((_) async => Success([agreement]));
        when(
          () => routeRateRepository.fetchRouteRates(),
        ).thenAnswer((_) async => const Success([]));
        when(() => workRepository.create(any())).thenAnswer((invocation) async {
          created = invocation.positionalArguments.first as WorkOrder;
          return Success(
            WorkOrder(
              id: 'saved-id',
              number: 'WO-1',
              customerId: 'c1',
              agreementId: 'a12',
              date: DateTime.now(),
              pickup: 'Pickup',
              destination: 'Destination',
            ),
          );
        });
        when(
          () => snackbarService.showCustomSnackBar(
            message: any(named: 'message'),
            variant: any(named: 'variant'),
          ),
        ).thenAnswer((_) => null);
        when(() => navigationService.back()).thenReturn(true);
        when(
          () => dialogService.showCustomDialog(
            title: any(named: 'title'),
            description: any(named: 'description'),
          ),
        ).thenAnswer((_) async => null);

        final viewModel = NewTripViewModel(
          workRepository: workRepository,
          partiesRepository: partiesRepository,
          vehicleRepository: vehicleRepository,
          driverRepository: driverRepository,
          agreementRepository: agreementRepository,
          routeRateRepository: routeRateRepository,
        );
        await viewModel.init();
        viewModel.step = 3;
        viewModel.customerId = 'c1';
        viewModel.selectVehicle(vehicle);
        viewModel.selectDriver(driver);
        viewModel.pickup.text = 'Pickup';
        viewModel.destination.text = 'Destination';
        viewModel.rate.text = '1200';

        await viewModel.next();

        expect(created?.id, isEmpty);
        expect(created?.number, isEmpty);
        expect(created?.allocations.single.supplierPayable, 0);
      },
    );
  });
}
