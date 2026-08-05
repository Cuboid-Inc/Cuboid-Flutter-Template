import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/reports/data/reports_repository.dart';
import 'package:fleetgo/ui/bottom_sheets/period/period_sheet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

class MockReportsRepository extends Mock implements ReportsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockReportsRepository reportsRepository;

  setUp(() {
    reportsRepository = MockReportsRepository();
    if (locator.isRegistered<ReportsRepository>()) {
      locator.unregister<ReportsRepository>();
    }
    locator.registerSingleton<ReportsRepository>(reportsRepository);
  });

  tearDown(locator.reset);

  test('init loads available years and reports failures', () async {
    when(
      () => reportsRepository.availableYears(),
    ).thenAnswer((_) async => const Success([2024, 2025, 2026]));
    final model = PeriodSheetModel(completer: (_) {}, request: SheetRequest());

    await model.init();
    expect(model.years, [2024, 2025, 2026]);
    expect(model.errorMessage, isNull);

    when(() => reportsRepository.availableYears()).thenAnswer(
      (_) async => const Failure(ValidationFailure('reports failed')),
    );
    await model.init();
    expect(model.errorMessage, 'reports failed');
  });

  test('select, maxMonth, and submit use the selected period', () {
    final selected = Period.month(DateTime.now().year - 1, 4);
    Period? saved;
    final model = PeriodSheetModel(
      completer: (response) => saved = response.data as Period?,
      request: SheetRequest(
        data: (selected: selected, resetTo: Period.thisMonth()),
      ),
    );

    expect(model.selected, selected);
    expect(model.maxMonth, 12);
    final currentYear = Period.month(DateTime.now().year, 1);
    model.select(currentYear);
    expect(model.selected, currentYear);
    expect(model.maxMonth, DateTime.now().month);
    model.submit();
    expect(saved, currentYear);
  });
}
