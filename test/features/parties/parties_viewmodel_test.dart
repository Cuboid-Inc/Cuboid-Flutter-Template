import 'dart:async';

import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/features/parties/ui/parties/parties_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../helpers/stacked_service_mocks.dart';

class MockPartiesRepository extends Mock implements PartiesRepository {}

void main() {
  late MockPartiesRepository repository;
  late MockBottomSheetService bottomSheetService;

  setUp(() {
    repository = MockPartiesRepository();
    bottomSheetService = MockBottomSheetService();
    replaceTestRegistration<BottomSheetService>(bottomSheetService);
  });

  tearDown(locator.reset);

  test('add exposes its busy state and ignores duplicate taps', () async {
    final response = Completer<SheetResponse<Party>?>();
    when(
      () => bottomSheetService.showCustomSheet<Party, Object?>(
        variant: any(named: 'variant'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).thenAnswer((_) => response.future);

    final viewModel = PartiesViewModel(repository);
    final add = viewModel.add();

    expect(viewModel.busy(PartiesBusy.addParty), isTrue);
    await viewModel.add();
    verify(
      () => bottomSheetService.showCustomSheet<Party, Object?>(
        variant: any(named: 'variant'),
        isScrollControlled: any(named: 'isScrollControlled'),
      ),
    ).called(1);

    response.complete();
    await add;
    expect(viewModel.busy(PartiesBusy.addParty), isFalse);
  });

  test('init loads the selected party page', () async {
    when(
      () => repository.fetchPage(
        pageNumber: 1,
        pageSize: 50,
        type: PartyType.customer,
      ),
    ).thenAnswer(
      (_) async => const Success(
        PaginatedResult(
          items: [Party(id: '1', name: 'Acme', type: PartyType.customer)],
          pageNumber: 1,
          pageSize: 50,
          totalRecords: 1,
        ),
      ),
    );

    when(
      () => repository.fetchBalances(),
    ).thenAnswer((_) async => const Success([]));

    final viewModel = PartiesViewModel(repository);
    await viewModel.init();

    expect(viewModel.pagination.items.map((p) => p.name), ['Acme']);
    expect(viewModel.errorMessage, isNull);
  });

  test('selectType reloads with the selected type', () async {
    when(
      () => repository.fetchPage(
        pageNumber: 1,
        pageSize: 50,
        type: PartyType.supplier,
      ),
    ).thenAnswer(
      (_) async => const Success(
        PaginatedResult(
          items: [Party(id: '2', name: 'Rentals Co', type: PartyType.supplier)],
          pageNumber: 1,
          pageSize: 50,
          totalRecords: 1,
        ),
      ),
    );

    when(
      () => repository.fetchBalances(),
    ).thenAnswer((_) async => const Success([]));

    final viewModel = PartiesViewModel(repository);
    viewModel.selectType(PartyType.supplier);
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.selectedType, PartyType.supplier);
    expect(viewModel.pagination.items.single.name, 'Rentals Co');
    verify(
      () => repository.fetchPage(
        pageNumber: 1,
        pageSize: 50,
        type: PartyType.supplier,
      ),
    ).called(1);
  });

  test('create reloads the selected page', () async {
    final party = const Party(id: '1', name: 'Acme', type: PartyType.customer);
    when(
      () => repository.fetchPage(
        pageNumber: 1,
        pageSize: 50,
        type: PartyType.customer,
      ),
    ).thenAnswer(
      (_) async => const Success(
        PaginatedResult(
          items: [Party(id: '1', name: 'Acme', type: PartyType.customer)],
          pageNumber: 1,
          pageSize: 50,
          totalRecords: 1,
        ),
      ),
    );
    when(
      () => repository.create(party),
    ).thenAnswer((_) async => Success(party));

    when(
      () => repository.fetchBalances(),
    ).thenAnswer((_) async => const Success([]));

    final viewModel = PartiesViewModel(repository);
    await viewModel.create(party);

    expect(viewModel.pagination.items, [party]);
    verify(() => repository.create(party)).called(1);
    verify(
      () => repository.fetchPage(
        pageNumber: 1,
        pageSize: 50,
        type: PartyType.customer,
      ),
    ).called(1);
  });

  test('fetchPage Failure sets pagination error', () async {
    when(
      () => repository.fetchPage(
        pageNumber: 1,
        pageSize: 50,
        type: PartyType.customer,
      ),
    ).thenAnswer((_) async => const Failure(ValidationFailure('boom')));

    when(
      () => repository.fetchBalances(),
    ).thenAnswer((_) async => const Success([]));

    final viewModel = PartiesViewModel(repository);
    await viewModel.init();

    expect(viewModel.pagination.error, 'boom');
  });
}
