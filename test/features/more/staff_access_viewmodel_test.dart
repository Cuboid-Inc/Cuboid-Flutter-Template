import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/models/business_profile.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/more/data/staff_repository.dart';
import 'package:fleetgo/features/more/ui/staff_access/staff_access_viewmodel.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../helpers/stacked_service_mocks.dart';

class MockStaffRepository extends Mock implements StaffRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

AuthAccess owner() => const AuthAccess(
  memberId: 'm', tenantId: 't', tenantName: 'Tenant', email: 'a@b.com',
  displayName: 'A', role: StaffRole.owner, status: MembershipStatus.active,
  accessPacks: {},
);
StaffMember staff([Set<AccessPack> packs = const {}]) => StaffMember(
  id: 's', name: 'Staff', email: 'staff@example.com', accessPacks: packs,
);

void main() {
  late MockStaffRepository repository;
  late MockAuthRepository auth;
  late MockBottomSheetService sheets;
  late MockNavigationService navigation;
  late MockSnackbarService snackbar;
  setUp(() {
    repository = MockStaffRepository();
    auth = MockAuthRepository();
    sheets = MockBottomSheetService();
    navigation = MockNavigationService();
    snackbar = MockSnackbarService();
    replaceTestRegistration<AuthRepository>(auth);
    replaceTestRegistration<BottomSheetService>(sheets);
    replaceTestRegistration<NavigationService>(navigation);
    replaceTestRegistration<SnackbarService>(snackbar);
    when(() => navigation.replaceWith(any(), arguments: any(named: 'arguments')))
        .thenAnswer((_) async => null);
  });
  tearDown(locator.reset);

  test('redirects non owners and loads staff for owners', () async {
    when(() => auth.currentAccess).thenReturn(null);
    final model = StaffAccessViewModel(repository);
    await model.init();
    verify(() => navigation.replaceWith(Routes.accessUnavailableView,
      arguments: any(named: 'arguments'))).called(1);
    when(() => auth.currentAccess).thenReturn(owner());
    when(() => repository.fetchStaff('t')).thenAnswer((_) async => Success([staff()]));
    await model.init();
    expect(model.staff, hasLength(1));
  });

  test('loads failure and formats access packs', () async {
    when(() => auth.currentAccess).thenReturn(owner());
    when(() => repository.fetchStaff('t')).thenAnswer(
      (_) async => const Failure(ValidationFailure('failed')),
    );
    final model = StaffAccessViewModel(repository);
    await model.init();
    expect(model.errorMessage, 'failed');
    expect(model.packsLabel(StaffMember(
      id: 'o', name: 'Owner', email: 'o@e.com', role: StaffRole.owner,
    )), contains('Operations'));
    expect(model.packsLabel(staff()), 'No access packs assigned');
    expect(model.packsLabel(staff({AccessPack.money})), 'Money');
  });

  test('invites staff on success and reports failure', () async {
    when(() => auth.currentAccess).thenReturn(owner());
    when(() => repository.fetchStaff('t')).thenAnswer((_) async => Success([staff()]));
    final invitee = staff({AccessPack.operations});
    when(() => sheets.showCustomSheet<StaffMember, dynamic>(
      variant: any(named: 'variant'), isScrollControlled: any(named: 'isScrollControlled'),
    )).thenAnswer((_) async => SheetResponse(data: invitee));
    when(() => repository.inviteStaff(invitee)).thenAnswer((_) async => Success(invitee));
    final model = StaffAccessViewModel(repository);
    await model.invite();
    verify(() => repository.inviteStaff(invitee)).called(1);
    verify(() => repository.fetchStaff('t')).called(1);
    when(() => repository.inviteStaff(invitee)).thenAnswer(
      (_) async => const Failure(ValidationFailure('invite failed')),
    );
    await model.invite();
    verify(() => locator<SnackbarService>().showCustomSnackBar(message: 'invite failed', variant: SnackbarType.error)).called(1);
  });
}
