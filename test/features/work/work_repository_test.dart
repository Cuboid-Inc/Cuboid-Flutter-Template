import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/work/data/work_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test(
    'work operations return guard failures without Supabase config',
    () async {
      final repository = WorkRepository(MockAuthRepository());
      final work = WorkOrder(
        id: '',
        number: '',
        customerId: 'customer',
        agreementId: 'agreement',
        date: DateTime(2026, 7, 18),
        pickup: 'A',
        destination: 'B',
        status: WorkStatus.planned,
      );

      expect(await repository.fetchAll(), isA<Failure<List<WorkOrder>>>());
      expect(
        await repository.fetchPage(pageNumber: 1),
        isA<Failure<PaginatedResult<WorkOrder>>>(),
      );
      expect(
        await repository.fetchPage(
          pageNumber: 2,
          pageSize: 10,
          status: WorkStatus.completed,
          search: 'WO',
        ),
        isA<Failure<PaginatedResult<WorkOrder>>>(),
      );
      expect(await repository.fetchOne('work'), isA<Failure<WorkOrder>>());
      expect(await repository.create(work), isA<Failure<WorkOrder>>());
      expect(await repository.complete('work'), isA<Failure<WorkOrder>>());
      expect(await repository.cancel('work'), isA<Failure<WorkOrder>>());
      expect(await repository.duplicate('work'), isA<Failure<WorkOrder>>());
      repository.invalidateCache();
    },
  );
}
