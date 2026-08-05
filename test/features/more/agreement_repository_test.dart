import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/agreement.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/more/data/agreement_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test(
    'agreement operations return guard failures without Supabase config',
    () async {
      final repository = AgreementRepository(MockAuthRepository());
      final agreement = Agreement(
        id: '',
        reference: 'AGR-1',
        name: 'Daily route',
        customerId: 'customer',
        rateModel: RateModel.perTrip,
      );

      expect(
        await repository.fetchAgreements(),
        isA<Failure<List<Agreement>>>(),
      );
      expect(
        await repository.fetchAgreementsPage(pageNumber: 1),
        isA<Failure<PaginatedResult<Agreement>>>(),
      );
      expect(
        await repository.fetchAgreementsPage(
          pageNumber: 2,
          pageSize: 10,
          search: 'route',
        ),
        isA<Failure<PaginatedResult<Agreement>>>(),
      );
      expect(
        await repository.addAgreement(agreement),
        isA<Failure<Agreement>>(),
      );
      expect(
        await repository.addAgreement(
          Agreement(
            id: 'agreement',
            reference: 'AGR-1',
            name: 'Daily route',
            customerId: 'customer',
            rateModel: RateModel.monthly,
          ),
        ),
        isA<Failure<Agreement>>(),
      );
      expect(
        await repository.archiveAgreement('agreement'),
        isA<Failure<void>>(),
      );
      repository.invalidateCache();
    },
  );
}
