import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/models/driver.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/more/data/driver_repository.dart';
import 'package:fleetgo/features/more/ui/driver_detail/driver_detail_viewmodel.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../helpers/stacked_service_mocks.dart';

class MockDriverRepository extends Mock implements DriverRepository {}
class MockPartiesRepository extends Mock implements PartiesRepository {}

class FakeDriver extends Fake implements Driver {}

Driver driver([String id = 'd']) => Driver(id: id, name: 'Driver');

void main() {
  late MockDriverRepository repository;
  late MockPartiesRepository parties;
  late MockBottomSheetService sheets;
  late MockNavigationService navigation;
  late MockSnackbarService snackbar;
  setUpAll(() => registerFallbackValue(FakeDriver()));
  setUp(() {
    repository = MockDriverRepository();
    parties = MockPartiesRepository();
    sheets = MockBottomSheetService();
    navigation = MockNavigationService();
    snackbar = MockSnackbarService();
    replaceTestRegistration<PartiesRepository>(parties);
    replaceTestRegistration<BottomSheetService>(sheets);
    replaceTestRegistration<NavigationService>(navigation);
    replaceTestRegistration<SnackbarService>(snackbar);
    when(() => navigation.back()).thenReturn(true);
  });
  tearDown(locator.reset);

  test('loads suppliers and formats names', () async {
    final supplier = const Party(id: 'p', name: 'Supplier', type: PartyType.supplier);
    when(() => parties.fetchAll()).thenAnswer((_) async => Success([supplier]));
    final model = DriverDetailViewModel(driver(), repository: repository);
    await model.init();
    expect(model.getSupplierName(null), '—');
    expect(model.getSupplierName('p'), 'Supplier');
    expect(model.getSupplierName('missing'), 'Unknown Supplier (missing)');
  });

  test('reports init, edit, and archive failures', () async {
    when(() => parties.fetchAll()).thenAnswer(
      (_) async => const Failure(ValidationFailure('parties failed')),
    );
    final model = DriverDetailViewModel(driver(), repository: repository);
    await model.init();
    verify(() => snackbar.showCustomSnackBar(message: 'parties failed', variant: SnackbarType.error)).called(1);
    when(() => sheets.showCustomSheet<Driver, Driver>(
      variant: any(named: 'variant'), data: any(named: 'data'),
      isScrollControlled: any(named: 'isScrollControlled'),
    )).thenAnswer((_) async => SheetResponse(data: driver('updated')));
    when(() => repository.addDriver(any())).thenAnswer(
      (_) async => const Failure(ValidationFailure('edit failed')),
    );
    await model.editDriver();
    verify(() => snackbar.showCustomSnackBar(message: 'edit failed', variant: SnackbarType.error)).called(1);
    when(() => repository.archiveDriver('d')).thenAnswer(
      (_) async => const Failure(ValidationFailure('archive failed')),
    );
    await model.archiveDriver();
    verify(() => snackbar.showCustomSnackBar(message: 'archive failed', variant: SnackbarType.error)).called(1);
  });

  test('edits and archives successfully', () async {
    final updated = driver('updated');
    when(() => parties.fetchAll()).thenAnswer((_) async => const Success([]));
    when(() => sheets.showCustomSheet<Driver, Driver>(
      variant: any(named: 'variant'), data: any(named: 'data'),
      isScrollControlled: any(named: 'isScrollControlled'),
    )).thenAnswer((_) async => SheetResponse(data: updated));
    when(() => repository.addDriver(updated)).thenAnswer((_) async => Success(updated));
    when(() => repository.archiveDriver('updated')).thenAnswer((_) async => const Success(null));
    final model = DriverDetailViewModel(driver(), repository: repository);
    await model.editDriver();
    expect(model.driver, updated);
    await model.archiveDriver();
    verify(() => navigation.back()).called(1);
  });
}
