import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/features/shell/shell_service.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:cuboid_flutter_template/features/work/ui/widgets/work_card.dart';
import 'package:cuboid_flutter_template/features/work/ui/widgets/work_filter.dart';
import 'package:cuboid_flutter_template/features/work/ui/work_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

class MockWorkRepository extends Mock implements WorkRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

class MockNavigationService extends Mock implements NavigationService {}

class TestWorkViewModel extends WorkViewModel {
  TestWorkViewModel() : super(MockWorkRepository(), MockPartiesRepository());

  var opened = false;

  @override
  String customerFor(WorkOrder work) => 'Customer';

  @override
  String dateFor(WorkOrder work) => '18 Jul 2026';

  @override
  String totalFor(WorkOrder work) => 'AED 100.00';

  @override
  Future<void> openDetail(WorkOrder work, int index) async => opened = true;
}

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUp(() {
    locator.reset();
    locator.registerSingleton<ShellService>(ShellService());
    locator.registerSingleton<NavigationService>(MockNavigationService());
  });

  tearDown(locator.reset);

  testWidgets('WorkFilter renders selected and unselected states', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      app(
        Row(
          children: [
            WorkFilter(label: 'All', selected: true, onTap: () => taps++),
            WorkFilter(
              label: 'Completed',
              selected: false,
              onTap: () => taps++,
            ),
          ],
        ),
      ),
    );
    expect(find.text('All'), findsOneWidget);
    await tester.tap(find.text('Completed'));
    expect(taps, 1);
  });

  testWidgets('WorkCard renders its fields and status', (tester) async {
    final viewModel = TestWorkViewModel();
    final work = WorkOrder(
      id: 'w1',
      number: 'WO-1',
      customerId: 'c1',
      date: DateTime(2026, 7, 18),
      pickup: 'Dubai',
      destination: 'Abu Dhabi',
      status: WorkStatus.completed,
    );
    await tester.pumpWidget(app(WorkCard(work: work, vm: viewModel, index: 0)));
    expect(find.text('WO-1'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Dubai → Abu Dhabi'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    await tester.tap(find.text('WO-1'));
    expect(viewModel.opened, isTrue);
  });
}
