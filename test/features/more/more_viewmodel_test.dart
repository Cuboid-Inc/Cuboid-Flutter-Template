import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/more/data/more_repository.dart';
import 'package:fleetgo/features/more/ui/more_viewmodel.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../helpers/stacked_service_mocks.dart';

class MockMoreRepository extends Mock implements MoreRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

MoreMenuCounts counts() => const MoreMenuCounts(
  customers: 1, suppliers: 2, vehiclesActive: 3, vehiclesExternal: 4,
  drivers: 5, agreements: 6, routeRates: 7, staff: 8,
);

AuthAccess access({bool owner = false}) => AuthAccess(
  memberId: 'm', tenantId: 't', tenantName: 'Tenant', email: 'a@b.com',
  displayName: 'A', role: owner ? StaffRole.owner : StaffRole.staff,
  status: MembershipStatus.active,
  accessPacks: owner ? {} : {AccessPack.reports},
);

void main() {
  late MockMoreRepository repository;
  late MockAuthRepository auth;
  late MockNavigationService navigation;
  late MockDialogService dialog;
  late MockSnackbarService snackbar;
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'FleetGo', packageName: 'com.cuboidinc.fleetgo',
      version: '0.1.0', buildNumber: '1', buildSignature: '',
    );
    repository = MockMoreRepository();
    auth = MockAuthRepository();
    navigation = MockNavigationService();
    dialog = MockDialogService();
    snackbar = MockSnackbarService();
    replaceTestRegistration<AuthRepository>(auth);
    replaceTestRegistration<NavigationService>(navigation);
    replaceTestRegistration<DialogService>(dialog);
    replaceTestRegistration<SnackbarService>(snackbar);
    when(() => navigation.navigateTo(any(), arguments: any(named: 'arguments')))
        .thenAnswer((_) async => null);
    when(() => navigation.clearStackAndShow(any())).thenAnswer((_) async => null);
  });
  tearDown(locator.reset);

  test('loads counts, exposes permissions, refreshes, and opens routes', () async {
    when(() => auth.currentAccess).thenReturn(access());
    when(() => repository.fetchMenuCounts()).thenAnswer((_) async => Success(counts()));
    final model = MoreViewModel(repository);
    expect(model.isOwner, isFalse);
    expect(model.hasReports, isTrue);
    await model.init();
    expect(model.menuCounts, counts());
    await model.openParties();
    await model.refreshSummery();
    verify(() => repository.invalidateCache()).called(1);
    model.openReports();
    await model.openBusinessProfile();
    model.toast('hello');
  });

  test('reports count failure and handles logout branches', () async {
    when(() => auth.currentAccess).thenReturn(access(owner: true));
    when(() => repository.fetchMenuCounts()).thenAnswer(
      (_) async => const Failure(ValidationFailure('counts failed')),
    );
    final model = MoreViewModel(repository);
    await model.init();
    expect(model.errorMessage, 'counts failed');
    expect(model.isOwner, isTrue);
    when(() => dialog.showCustomDialog(
      variant: any(named: 'variant'), title: any(named: 'title'),
      description: any(named: 'description'),
    )).thenAnswer((_) async => null);
    await model.logout();
    verifyNever(() => auth.signOut());
    when(() => dialog.showCustomDialog(
      variant: any(named: 'variant'), title: any(named: 'title'),
      description: any(named: 'description'),
    )).thenAnswer((_) async => DialogResponse(confirmed: true));
    when(() => auth.signOut()).thenAnswer(
      (_) async => const Failure(ValidationFailure('logout failed')),
    );
    await model.logout();
    verify(() => snackbar.showCustomSnackBar(message: 'logout failed', variant: SnackbarType.error)).called(1);
    when(() => auth.signOut()).thenAnswer((_) async => const Success(null));
    await model.logout();
    verify(() => navigation.clearStackAndShow(Routes.loginView)).called(1);
  });
}
