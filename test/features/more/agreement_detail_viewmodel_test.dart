import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/more/data/agreement_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/features/more/ui/agreement_detail/agreement_detail_viewmodel.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockAgreementRepository extends Mock implements AgreementRepository {}

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

Agreement agreement([String id = 'a']) => Agreement(
  id: id,
  reference: 'R',
  name: 'Agreement',
  customerId: 'c',
  rateModel: RateModel.perTrip,
);
Vehicle vehicle() => Vehicle(
  id: 'v',
  plateNumber: 'P',
  label: 'Truck',
  vehicleClass: VehicleClass.threeTon,
  ownership: VehicleOwnership.owned,
);

void main() {
  late MockAgreementRepository repository;
  late MockVehicleRepository vehicleRepository;
  late MockPartiesRepository partiesRepository;
  late MockBottomSheetService sheets;
  late MockNavigationService navigation;
  late MockSnackbarService snackbar;
  setUp(() {
    repository = MockAgreementRepository();
    vehicleRepository = MockVehicleRepository();
    partiesRepository = MockPartiesRepository();
    sheets = MockBottomSheetService();
    navigation = MockNavigationService();
    snackbar = MockSnackbarService();
    replaceTestRegistration<PartiesRepository>(partiesRepository);
    replaceTestRegistration<BottomSheetService>(sheets);
    replaceTestRegistration<NavigationService>(navigation);
    replaceTestRegistration<SnackbarService>(snackbar);
    when(() => navigation.back()).thenReturn(true);
  });
  tearDown(locator.reset);

  test('loads parties and vehicles and formats labels', () async {
    when(() => partiesRepository.fetchAll()).thenAnswer(
      (_) async => const Success([
        Party(id: 'c', name: 'Customer', type: PartyType.customer),
      ]),
    );
    when(
      () => vehicleRepository.fetchVehicles(),
    ).thenAnswer((_) async => Success([vehicle()]));
    final model = AgreementDetailViewModel(
      agreement(),
      repository: repository,
      vehicleRepository: vehicleRepository,
    );
    await model.init();
    expect(model.getCustomerName('c'), 'Customer');
    expect(model.getCustomerName('x'), 'Unknown Customer (x)');
    expect(model.getVehicleLabel(null), '—');
    expect(model.getVehicleLabel('v'), 'Truck');
    expect(model.getVehicleLabel('x'), 'Unknown Vehicle (x)');
  });

  test('handles init and action failures', () async {
    when(() => partiesRepository.fetchAll()).thenAnswer(
      (_) async => const Failure(ValidationFailure('parties failed')),
    );
    when(() => vehicleRepository.fetchVehicles()).thenAnswer(
      (_) async => const Failure(ValidationFailure('vehicles failed')),
    );
    final model = AgreementDetailViewModel(
      agreement(),
      repository: repository,
      vehicleRepository: vehicleRepository,
    );
    await model.init();
    verify(
      () => snackbar.showCustomSnackBar(
        message: 'parties failed',
        variant: SnackbarType.error,
      ),
    ).called(1);
    verify(
      () => snackbar.showCustomSnackBar(
        message: 'vehicles failed',
        variant: SnackbarType.error,
      ),
    ).called(1);
    final updated = agreement('updated');
    when(
      () => sheets.showCustomSheet<Agreement, Agreement>(
        variant: any(named: 'variant'),
        data: any(named: 'data'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer((_) async => SheetResponse(data: updated));
    when(
      () => repository.addAgreement(updated),
    ).thenAnswer((_) async => const Failure(ValidationFailure('edit failed')));
    await model.editAgreement();
    when(() => repository.archiveAgreement('a')).thenAnswer(
      (_) async => const Failure(ValidationFailure('archive failed')),
    );
    await model.archiveAgreement();
    verify(
      () => snackbar.showCustomSnackBar(
        message: 'edit failed',
        variant: SnackbarType.error,
      ),
    ).called(1);
    verify(
      () => snackbar.showCustomSnackBar(
        message: 'archive failed',
        variant: SnackbarType.error,
      ),
    ).called(1);
  });

  test('edits and archives successfully', () async {
    final updated = agreement('updated');
    when(
      () => partiesRepository.fetchAll(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => vehicleRepository.fetchVehicles(),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => sheets.showCustomSheet<Agreement, Agreement>(
        variant: any(named: 'variant'),
        data: any(named: 'data'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer((_) async => SheetResponse(data: updated));
    when(
      () => repository.addAgreement(updated),
    ).thenAnswer((_) async => Success(updated));
    when(
      () => repository.archiveAgreement('updated'),
    ).thenAnswer((_) async => const Success(null));
    final model = AgreementDetailViewModel(
      agreement(),
      repository: repository,
      vehicleRepository: vehicleRepository,
    );
    await model.editAgreement();
    expect(model.agreement, updated);
    await model.archiveAgreement();
    verify(() => navigation.back()).called(1);
  });
}
