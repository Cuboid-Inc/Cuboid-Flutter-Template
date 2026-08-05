import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/reports/data/reports_repository.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

typedef PeriodSheetData = ({Period selected, Period resetTo});

class PeriodSheetModel extends BaseViewModel {
  PeriodSheetModel({required this.completer, required this.request})
    : selected = (request.data as PeriodSheetData?)?.selected ?? Period.thisMonth(),
      _resetTo = (request.data as PeriodSheetData?)?.resetTo ?? Period.thisMonth(),
      years = [DateTime.now().year];

  final Function(SheetResponse response) completer;
  final SheetRequest request;
  final Period _resetTo;
  Period selected;
  List<int> years;
  String? errorMessage;

  Future<void> init() async {
    switch (await locator<ReportsRepository>().availableYears()) {
      case Success(:final value):
        years = value;
        notifyListeners();
      case Failure(:final failure):
        errorMessage = failure.message;
    }
  }

  int get maxMonth =>
      selected.start.year == DateTime.now().year ? DateTime.now().month : 12;

  // A period is "custom" whenever it isn't exactly a full-month or
  // full-year span, i.e. not something a quick-pick chip could produce.
  bool get isCustom {
    final s = selected.start;
    return selected != Period.month(s.year, s.month) &&
        selected != Period.year(s.year);
  }

  void select(Period period) {
    selected = period;
    notifyListeners();
  }

  void reset() {
    selected = _resetTo;
    submit();
  }

  void submit() =>
      completer(SheetResponse<Period>(confirmed: true, data: selected));
}
