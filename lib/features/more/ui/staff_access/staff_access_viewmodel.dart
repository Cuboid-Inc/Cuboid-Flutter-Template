import 'package:cuboid_flutter_template/app/app.bottomsheets.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/staff_repository.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum StaffAccessBusy { inviteStaff }

class StaffAccessViewModel extends BaseViewModel {
  StaffAccessViewModel([StaffRepository? repository])
    : _repository = repository ?? locator<StaffRepository>();

  final StaffRepository _repository;
  final _snackbar = locator<SnackbarService>();
  final _bottomSheets = locator<BottomSheetService>();
  final _auth = locator<AuthRepository>();
  final _navigation = locator<NavigationService>();
  List<StaffMember> staff = const [];
  String? errorMessage;

  Future<void> init() async {
    final tenantId = _auth.currentAccess?.tenantId;
    if (_auth.currentAccess?.isOwner != true || tenantId == null) {
      await _navigation.replaceWith(
        Routes.accessUnavailableView,
        arguments: const AccessUnavailableViewArguments(
          title: 'Access unavailable',
          message: 'Owner access is required for staff management.',
        ),
      );
      return;
    }
    setBusy(true);
    errorMessage = null;
    switch (await _repository.fetchStaff(tenantId)) {
      case Success(:final value):
        staff = value;
      case Failure(:final failure):
        errorMessage = failure.message;
        _snackbar.showError(failure.message);
    }
    setBusy(false);
  }

  String packsLabel(StaffMember member) => member.role == StaffRole.owner
      ? AccessPack.values.map((p) => p.label).join(' · ')
      : member.accessPacks.isEmpty
      ? 'No access packs assigned'
      : member.accessPacks.map((p) => p.label).join(' · ');

  Future<void> invite() async {
    if (busy(StaffAccessBusy.inviteStaff)) return;
    await runBusyFuture(() async {
      final response = await _bottomSheets
          .showCustomSheet<StaffMember, dynamic>(
            variant: BottomSheetType.inviteStaffForm,
            isScrollControlled: true,
          );
      final invitee = response?.data;
      if (invitee == null) return;

      switch (await _repository.inviteStaff(invitee)) {
        case Success():
          await init();
          _snackbar.showSuccess('Invitation sent to ${invitee.email}');
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: StaffAccessBusy.inviteStaff);
  }
}
