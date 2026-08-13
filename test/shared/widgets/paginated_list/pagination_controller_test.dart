import 'package:cuboid_flutter_template/core/errors/failures.dart';
import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:cuboid_flutter_template/core/errors/result.dart';
import 'package:cuboid_flutter_template/shared/widgets/paginated_list/pagination_controller.dart';
import 'package:flutter_test/flutter_test.dart';

PaginatedResult<int> page(int number, List<int> items) => PaginatedResult(
  items: items,
  pageNumber: number,
  pageSize: 2,
  totalRecords: 5,
);

void main() {
  test('loadInitial populates state and uses the default page size', () async {
    var requestedPageSize = 0;
    var changes = 0;
    final controller = PaginationController<int>(
      callback: (pageNumber, pageSize) async {
        requestedPageSize = pageSize;
        return Success(page(pageNumber, [1, 2]));
      },
      onStateChanged: () => changes++,
    );

    await controller.loadInitial();

    expect(requestedPageSize, 50);
    expect(controller.items, [1, 2]);
    expect(controller.currentPage, 1);
    expect(controller.totalRecords, 5);
    expect(controller.totalPages, 3);
    expect(controller.hasMore, isTrue);
    expect(controller.isLoading, isFalse);
    expect(changes, 2);
  });

  test('loadInitial failure sets error', () async {
    var shouldFail = true;
    final controller = PaginationController<int>(
      callback: (pageNumber, _) async {
        if (shouldFail) {
          shouldFail = false;
          return const Failure(ValidationFailure('failed'));
        }
        return Success(page(pageNumber, [1, 2]));
      },
    );

    await controller.loadInitial();

    expect(controller.error, 'failed');
    expect(controller.items, isEmpty);
    expect(controller.isEmpty, isTrue);
    expect(controller.hasInitialFailure, isTrue);
    expect(controller.isGenuinelyEmpty, isFalse);

    await controller.retry();
    expect(controller.items, [1, 2]);
    expect(controller.hasInitialFailure, isFalse);
  });

  test('loadMore appends pages and stops at the last page', () async {
    final controller = PaginationController<int>(
      pageSize: 2,
      callback: (pageNumber, _) async => switch (pageNumber) {
        1 => Success(page(1, [1, 2])),
        2 => Success(page(2, [3, 4])),
        3 => Success(page(3, [5])),
        _ => throw StateError('unexpected page'),
      },
    );

    await controller.loadInitial();
    await controller.loadMore();
    await controller.loadMore();
    await controller.loadMore();

    expect(controller.items, [1, 2, 3, 4, 5]);
    expect(controller.currentPage, 3);
    expect(controller.hasMore, isFalse);
  });

  test('loadMore failure keeps existing items', () async {
    var pageTwo = true;
    final controller = PaginationController<int>(
      pageSize: 2,
      callback: (pageNumber, _) async {
        if (pageNumber == 2 && pageTwo) {
          pageTwo = false;
          return const Failure(ServerFailure('failed'));
        }
        return Success(page(pageNumber, pageNumber == 1 ? [1, 2] : [3, 4]));
      },
    );

    await controller.loadInitial();
    await controller.loadMore();

    expect(controller.items, [1, 2]);
    expect(controller.currentPage, 1);
    expect(controller.isLoadingMore, isFalse);
    expect(controller.hasLoadMoreFailure, isTrue);
    expect(controller.hasItemsFailure, isTrue);

    await controller.retry();
    expect(controller.items, [1, 2, 3, 4]);
    expect(controller.hasItemsFailure, isFalse);
  });

  test('refresh replaces items and clears error', () async {
    var request = 0;
    final controller = PaginationController<int>(
      pageSize: 2,
      callback: (pageNumber, _) async {
        request++;
        if (request == 2) return const Failure(ServerFailure('failed'));
        return Success(page(pageNumber, request == 1 ? [1, 2] : [9]));
      },
    );

    await controller.loadInitial();
    await controller.refresh();
    expect(controller.items, [1, 2]);
    expect(controller.error, 'failed');
    expect(controller.hasItemsFailure, isTrue);

    await controller.refresh();
    expect(controller.items, [9]);
    expect(controller.error, isNull);
  });

  test('dispose prevents state change callbacks', () async {
    var changes = 0;
    final controller = PaginationController<int>(
      callback: (_, _) async => Success(page(1, [1])),
      onStateChanged: () => changes++,
    );

    controller.dispose();
    await controller.loadInitial();

    expect(changes, 0);
  });
}
