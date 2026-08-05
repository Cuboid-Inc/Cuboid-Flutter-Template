import 'package:fleetgo/core/models/driver.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/more/data/driver_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test(
    'driver operations return guard failures without Supabase config',
    () async {
      final repository = DriverRepository(MockAuthRepository());
      final driver = Driver(id: '', name: 'Driver');

      expect(await repository.fetchDrivers(), isA<Failure<List<Driver>>>());
      expect(
        await repository.fetchDriversPage(pageNumber: 1),
        isA<Failure<PaginatedResult<Driver>>>(),
      );
      expect(
        await repository.fetchDriversPage(
          pageNumber: 2,
          pageSize: 10,
          search: 'Ali',
        ),
        isA<Failure<PaginatedResult<Driver>>>(),
      );
      expect(await repository.addDriver(driver), isA<Failure<Driver>>());
      expect(
        await repository.addDriver(Driver(id: 'driver', name: 'Driver')),
        isA<Failure<Driver>>(),
      );
      expect(await repository.archiveDriver('driver'), isA<Failure<void>>());
      repository.invalidateCache();
    },
  );
}
