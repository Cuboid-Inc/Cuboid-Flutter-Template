import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/models/report_models.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test(
    'party operations return guard failures without Supabase config',
    () async {
      final repository = PartiesRepository(MockAuthRepository());
      const party = Party(id: '', name: 'Customer', type: PartyType.customer);

      expect(await repository.fetchAll(), isA<Failure<List<Party>>>());
      expect(
        await repository.partiesForDirection(PaymentDirection.incoming),
        isA<Failure<List<Party>>>(),
      );
      expect(
        await repository.partiesForDirection(PaymentDirection.outgoing),
        isA<Failure<List<Party>>>(),
      );
      expect(
        await repository.fetchPage(pageNumber: 1),
        isA<Failure<PaginatedResult<Party>>>(),
      );
      expect(
        await repository.fetchPage(
          pageNumber: 2,
          pageSize: 10,
          type: PartyType.supplier,
          search: 'Supplier',
        ),
        isA<Failure<PaginatedResult<Party>>>(),
      );
      expect(await repository.create(party), isA<Failure<Party>>());
      expect(
        await repository.create(
          const Party(id: 'party', name: 'Customer', type: PartyType.customer),
        ),
        isA<Failure<Party>>(),
      );
      expect(await repository.archive('party'), isA<Failure<void>>());
      expect(
        await repository.fetchBalances(),
        isA<Failure<List<PartyBalance>>>(),
      );
      repository.invalidateCache();
    },
  );
}
