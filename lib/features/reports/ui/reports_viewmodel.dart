import 'package:fleetgo/app/app.bottomsheets.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/features/reports/data/report_type.dart';
import 'package:fleetgo/ui/bottom_sheets/period/period_sheet_model.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class ReportsViewModel extends BaseViewModel {
  final _snackbar = locator<SnackbarService>();
  final _bottomSheets = locator<BottomSheetService>();
  Period period = Period.thisMonth();
  bool get hasCustomPeriod => period != Period.thisMonth();

  Future<void> choosePeriod() async {
    final response = await _bottomSheets
        .showCustomSheet<Period, PeriodSheetData>(
          variant: BottomSheetType.period,
          data: (selected: period, resetTo: Period.thisMonth()),
          isScrollControlled: true,
        );
    final selected = response?.data;
    if (selected == null) return;
    period = selected;
    notifyListeners();
  }

  void export() => _snackbar.showInfo('Available after backend connect');

  void openReport(ReportType type) => locator<NavigationService>().navigateTo(
    Routes.reportDetailView,
    arguments: ReportDetailViewArguments(type: type, period: period),
  );
}
