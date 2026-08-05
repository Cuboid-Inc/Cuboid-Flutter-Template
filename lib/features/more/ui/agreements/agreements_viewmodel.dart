import 'package:fleetgo/app/app.bottomsheets.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/models/agreement.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/more/data/agreement_repository.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:fleetgo/ui/widgets/paginated_list/pagination_controller.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum AgreementsBusy { addAgreement }

class AgreementsViewModel extends BaseViewModel {
  final _repository = locator<AgreementRepository>();
  final _bottomSheets = locator<BottomSheetService>();
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();

  late final PaginationController<Agreement> pagination =
      PaginationController<Agreement>(
        callback: (pageNumber, pageSize) => _repository.fetchAgreementsPage(
          pageNumber: pageNumber,
          pageSize: pageSize,
          search: null,
        ),
        onStateChanged: notifyListeners,
      );

  Future<void> init() => pagination.loadInitial();

  Future<void> refreshList() async {
    _repository.invalidateCache();
    await pagination.refresh();
  }

  Future<void> addAgreement() async {
    if (busy(AgreementsBusy.addAgreement)) return;
    await runBusyFuture(() async {
      final response = await _bottomSheets.showCustomSheet<Agreement, dynamic>(
        variant: BottomSheetType.agreementForm,
        isScrollControlled: true,
      );
      final agreement = response?.data;
      if (agreement == null) return;
      switch (await _repository.addAgreement(agreement)) {
        case Success():
          await pagination.loadInitial();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: AgreementsBusy.addAgreement);
  }

  Future<void> openAgreement(Agreement agreement) async {
    await _navigation.navigateTo(
      Routes.agreementDetailView,
      arguments: AgreementDetailViewArguments(agreement: agreement),
    );
    await pagination.loadInitial();
  }

  @override
  void dispose() {
    pagination.dispose();
    super.dispose();
  }
}
