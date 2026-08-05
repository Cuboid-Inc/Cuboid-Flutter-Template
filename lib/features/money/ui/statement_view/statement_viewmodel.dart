import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/models/business_profile.dart';
import 'package:fleetgo/core/money.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/money/data/money_repository.dart';
import 'package:fleetgo/features/money/data/money_rows.dart';
import 'package:fleetgo/features/more/data/business_profile_repository.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/features/work/data/work_repository.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:fleetgo/ui/pdf/fleet_pdf.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class StatementViewModel extends BaseViewModel {
  StatementViewModel({
    required this.partyId,
    required this.period,
    MoneyRepository? repository,
    PartiesRepository? partiesRepository,
    WorkRepository? workRepository,
  }) : _moneyRepository = repository ?? locator<MoneyRepository>(),
       _partiesRepository = partiesRepository ?? locator<PartiesRepository>(),
       _workRepository = workRepository ?? locator<WorkRepository>();

  final String partyId;
  final Period period;
  final MoneyRepository _moneyRepository;
  final PartiesRepository _partiesRepository;
  final WorkRepository _workRepository;
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();
  Party? party;
  List<StatementRow> rows = const [];
  List<WorkOrder> workOrders = const [];
  BusinessProfile? businessProfile;

  num get total =>
      rows.fold<num>(0, (sum, row) => roundMoney(sum + row.amount));

  Future<void> init() async {
    setBusy(true);
    switch (await _partiesRepository.fetchAll()) {
      case Success(:final value):
        party = value.where((item) => item.id == partyId).firstOrNull;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _moneyRepository.statementRows(period)) {
      case Success(:final value):
        rows = value.where((row) => row.partyId == partyId).toList();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _workRepository.fetchAll()) {
      case Success(:final value):
        workOrders = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    switch (await _businessProfileRepository.fetchBusinessProfile()) {
      case Success(:final value):
        businessProfile = value;
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    setBusy(false);
  }

  // Helper getter to access business profile repository
  BusinessProfileRepository get _businessProfileRepository =>
      locator<BusinessProfileRepository>();

  void viewWorkOrder(StatementRow row) async {
    setBusy(true);
    switch (await _workRepository.fetchAll()) {
      case Success(:final value):
        final work = value.where((w) => w.id == row.workOrderId).firstOrNull;
        if (work != null) {
          _navigation.navigateTo(
            Routes.workDetailView,
            arguments: WorkDetailViewArguments(work: work),
          );
        } else {
          _snackbar.showInfo('Work order not found');
        }
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    setBusy(false);
  }

  String workOrderNumber(String id) =>
      workOrders.where((work) => work.id == id).firstOrNull?.number ?? id;

  void openPdf() {
    if (party == null || businessProfile == null) return;
    _navigation.navigateTo(
      Routes.pdfPreviewView,
      arguments: PdfPreviewViewArguments(
        title: '${party!.name} Statement.pdf',
        build: () => buildStatementPdf(
          party!,
          rows,
          period,
          businessProfile!,
          workOrderNumber,
        ),
      ),
    );
  }
}
