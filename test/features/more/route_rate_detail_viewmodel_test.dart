import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/models/route_rate.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/more/data/route_rate_repository.dart';
import 'package:fleetgo/features/more/ui/route_rate_detail/route_rate_detail_viewmodel.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../helpers/stacked_service_mocks.dart';

class MockRouteRateRepository extends Mock implements RouteRateRepository {}

RouteRate rate(String id) => RouteRate(
  id: id, appliesTo: 'All', pickup: 'A', destination: 'B',
  vehicleClass: VehicleClass.threeTon, rate: 100,
);

void main() {
  late MockRouteRateRepository repository;
  late MockBottomSheetService sheets;
  late MockNavigationService navigation;
  late MockSnackbarService snackbar;
  setUp(() {
    repository = MockRouteRateRepository();
    sheets = MockBottomSheetService();
    navigation = MockNavigationService();
    snackbar = MockSnackbarService();
    replaceTestRegistration<BottomSheetService>(sheets);
    replaceTestRegistration<NavigationService>(navigation);
    replaceTestRegistration<SnackbarService>(snackbar);
    when(() => navigation.back()).thenReturn(true);
  });
  tearDown(locator.reset);

  test('edits a route rate and handles no selection', () async {
    final updated = rate('r2');
    when(() => sheets.showCustomSheet<RouteRate, RouteRate>(
      variant: any(named: 'variant'), data: any(named: 'data'),
      isScrollControlled: any(named: 'isScrollControlled'),
    )).thenAnswer((_) async => SheetResponse(data: updated));
    when(() => repository.addRouteRate(updated))
        .thenAnswer((_) async => Success(updated));
    final model = RouteRateDetailViewModel(rate('r1'), repository: repository);
    await model.editRouteRate();
    expect(model.routeRate, updated);
    verify(() => snackbar.showCustomSnackBar(message: 'Route rate updated successfully', variant: SnackbarType.success)).called(1);
  });

  test('reports edit and archive failures, then archives successfully', () async {
    final original = rate('r1');
    when(() => sheets.showCustomSheet<RouteRate, RouteRate>(
      variant: any(named: 'variant'), data: any(named: 'data'),
      isScrollControlled: any(named: 'isScrollControlled'),
    )).thenAnswer((_) async => SheetResponse(data: original));
    when(() => repository.addRouteRate(original)).thenAnswer(
      (_) async => const Failure(ValidationFailure('edit failed')),
    );
    final model = RouteRateDetailViewModel(original, repository: repository);
    await model.editRouteRate();
    verify(() => snackbar.showCustomSnackBar(message: 'edit failed', variant: SnackbarType.error)).called(1);
    when(() => repository.archiveRouteRate('r1')).thenAnswer(
      (_) async => const Failure(ValidationFailure('archive failed')),
    );
    await model.archiveRouteRate();
    verify(() => snackbar.showCustomSnackBar(message: 'archive failed', variant: SnackbarType.error)).called(1);
    when(() => repository.archiveRouteRate('r1'))
        .thenAnswer((_) async => const Success(null));
    await model.archiveRouteRate();
    verify(() => navigation.back()).called(1);
  });
}
