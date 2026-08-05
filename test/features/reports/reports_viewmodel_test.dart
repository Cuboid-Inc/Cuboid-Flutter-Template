import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/app/app.router.dart';
import 'package:cuboid_flutter_template/core/models/period.dart';
import 'package:cuboid_flutter_template/features/reports/data/report_type.dart';
import 'package:cuboid_flutter_template/features/reports/ui/reports_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/period/period_sheet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

void main() {
  late MockBottomSheetService sheets;
  late MockNavigationService navigation;
  late MockSnackbarService snackbar;
  setUp(() {
    sheets = MockBottomSheetService();
    navigation = MockNavigationService();
    snackbar = MockSnackbarService();
    replaceTestRegistration<BottomSheetService>(sheets);
    replaceTestRegistration<NavigationService>(navigation);
    replaceTestRegistration<SnackbarService>(snackbar);
    when(
      () => navigation.navigateTo(any(), arguments: any(named: 'arguments')),
    ).thenAnswer((_) async => null);
  });
  tearDown(locator.reset);

  test('chooses a period and ignores an empty response', () async {
    final model = ReportsViewModel();
    final selected = Period.month(2026, 1);
    when(
      () => sheets.showCustomSheet<Period, PeriodSheetData>(
        variant: any(named: 'variant'),
        data: any(named: 'data'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer((_) async => SheetResponse(data: selected));
    await model.choosePeriod();
    expect(model.period, selected);
    when(
      () => sheets.showCustomSheet<Period, PeriodSheetData>(
        variant: any(named: 'variant'),
        data: any(named: 'data'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer((_) async => null);
    await model.choosePeriod();
    expect(model.period, selected);
  });

  test('exports and opens a report', () {
    final model = ReportsViewModel();
    model.export();
    model.openReport(ReportType.cashbook);
    verify(
      () => navigation.navigateTo(
        Routes.reportDetailView,
        arguments: any(named: 'arguments'),
      ),
    ).called(1);
  });
}
