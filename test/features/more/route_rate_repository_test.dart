import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/route_rate.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/more/data/route_rate_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test(
    'route-rate operations return guard failures without Supabase config',
    () async {
      final repository = RouteRateRepository(MockAuthRepository());
      final rate = RouteRate(
        id: '',
        appliesTo: 'customer',
        pickup: 'A',
        destination: 'B',
        vehicleClass: VehicleClass.threeTon,
        rate: 100,
      );

      expect(
        await repository.fetchRouteRates(),
        isA<Failure<List<RouteRate>>>(),
      );
      expect(
        await repository.fetchRouteRatesPage(pageNumber: 1),
        isA<Failure<PaginatedResult<RouteRate>>>(),
      );
      expect(
        await repository.fetchRouteRatesPage(
          pageNumber: 2,
          pageSize: 10,
          search: 'A',
        ),
        isA<Failure<PaginatedResult<RouteRate>>>(),
      );
      expect(await repository.addRouteRate(rate), isA<Failure<RouteRate>>());
      expect(
        await repository.addRouteRate(
          RouteRate(
            id: 'rate',
            appliesTo: 'customer',
            pickup: 'A',
            destination: 'B',
            vehicleClass: VehicleClass.sevenTon,
            rate: 200,
          ),
        ),
        isA<Failure<RouteRate>>(),
      );
      expect(await repository.archiveRouteRate('rate'), isA<Failure<void>>());
      repository.invalidateCache();
    },
  );
}
