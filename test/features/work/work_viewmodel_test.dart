import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/failures.dart';
import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/features/shell/shell_service.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:cuboid_flutter_template/features/work/ui/work_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockWorkRepository extends Mock implements WorkRepository {}

class MockPartiesRepository extends Mock implements PartiesRepository {}

void main() {
  late MockWorkRepository workRepository;
  late MockPartiesRepository partiesRepository;
  late MockNavigationService navigationService;

  setUp(() {
    workRepository = MockWorkRepository();
    partiesRepository = MockPartiesRepository();
    navigationService = MockNavigationService();
    locator.reset();
    locator.registerSingleton<ShellService>(ShellService());
    replaceTestRegistration<NavigationService>(navigationService);
    replaceTestRegistration<SnackbarService>(MockSnackbarService());
    replaceTestRegistration<BottomSheetService>(MockBottomSheetService());
  });

  tearDown(locator.reset);

  test('page load populates pagination items', () async {
    final work = WorkOrder(
      id: 'work-1',
      number: 'WO-1',
      customerId: 'customer-1',
      agreementId: 'agreement-1',
      date: DateTime(2026, 7, 17),
      pickup: 'Pickup',
      destination: 'Destination',
    );
    when(
      () => workRepository.fetchPage(
        pageNumber: 1,
        pageSize: 50,
        status: null,
        search: '',
      ),
    ).thenAnswer(
      (_) async => Success(
        PaginatedResult(
          items: [work],
          pageNumber: 1,
          pageSize: 50,
          totalRecords: 1,
        ),
      ),
    );
    when(
      () => partiesRepository.fetchAll(),
    ).thenAnswer((_) async => const Success(<Party>[]));

    final viewModel = WorkViewModel(workRepository, partiesRepository);
    await viewModel.init();

    expect(viewModel.pagination.items, [work]);
    viewModel.dispose();
  });

  test('filters, formats, refreshes, and updates a work order', () async {
    final original = WorkOrder(
      id: 'work-1',
      number: 'WO-1',
      customerId: 'customer-1',
      date: DateTime(2026, 7, 17),
      pickup: 'Pickup',
      destination: 'Destination',
      chargeLines: [const ChargeLine(name: 'Trip', unitPrice: 100)],
    );
    final updated = WorkOrder(
      id: 'work-1',
      number: 'WO-2',
      customerId: 'customer-1',
      date: DateTime(2026, 7, 17),
      pickup: 'Pickup',
      destination: 'Destination',
      status: WorkStatus.completed,
    );
    when(
      () => workRepository.fetchPage(
        pageNumber: 1,
        pageSize: 50,
        status: any(named: 'status'),
        search: any(named: 'search'),
      ),
    ).thenAnswer(
      (_) async => Success(
        PaginatedResult(
          items: [original],
          pageNumber: 1,
          pageSize: 50,
          totalRecords: 1,
        ),
      ),
    );
    when(() => partiesRepository.fetchAll()).thenAnswer(
      (_) async => const Success([
        Party(id: 'customer-1', name: 'Customer', type: PartyType.customer),
      ]),
    );
    when(
      () => navigationService.navigateTo(
        any(),
        arguments: any(named: 'arguments'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => workRepository.fetchOne('work-1'),
    ).thenAnswer((_) async => Success(updated));
    final model = WorkViewModel(workRepository, partiesRepository);
    await model.init();
    expect(model.customerFor(original), 'Customer');
    expect(model.customerFor(updated), 'Customer');
    expect(model.totalFor(original), contains('105'));
    expect(model.dateFor(original), isNotEmpty);
    expect(model.filters, hasLength(WorkStatus.values.length + 1));
    model.setQuery('WO');
    model.setFilter(WorkStatus.completed);
    await Future<void>.delayed(Duration.zero);
    await model.openDetail(original, 0);
    expect(model.pagination.items.first, updated);
    await model.openNewTrip();
    await model.openMonthlyExtra();
    model.dispose();
  });

  test('keeps an unknown customer and reports party failure', () async {
    final work = WorkOrder(
      id: 'w',
      number: 'W',
      customerId: 'missing',
      date: DateTime(2026),
      pickup: 'A',
      destination: 'B',
    );
    when(
      () => workRepository.fetchPage(
        pageNumber: 1,
        pageSize: 50,
        status: null,
        search: '',
      ),
    ).thenAnswer(
      (_) async => Success(
        PaginatedResult(
          items: [work],
          pageNumber: 1,
          pageSize: 50,
          totalRecords: 1,
        ),
      ),
    );
    when(
      () => partiesRepository.fetchAll(),
    ).thenAnswer((_) async => const Failure(ServerFailure('parties failed')));
    final model = WorkViewModel(workRepository, partiesRepository);
    await model.init();
    expect(model.customerFor(work), 'Unknown customer');
    expect(model.errorMessage, 'parties failed');
    model.dispose();
  });
}
