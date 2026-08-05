import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/more_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('stores all menu counts', () {
    const counts = MoreMenuCounts(
      customers: 1,
      suppliers: 2,
      vehiclesActive: 3,
      vehiclesExternal: 4,
      drivers: 5,
      agreements: 6,
      routeRates: 7,
      staff: 8,
    );

    expect(counts.customers, 1);
    expect(counts.suppliers, 2);
    expect(counts.vehiclesActive, 3);
    expect(counts.vehiclesExternal, 4);
    expect(counts.drivers, 5);
    expect(counts.agreements, 6);
    expect(counts.routeRates, 7);
    expect(counts.staff, 8);
  });

  test(
    'fetchMenuCounts returns the guard failure without Supabase config',
    () async {
      final repository = MoreRepository(MockAuthRepository());
      final result = await repository.fetchMenuCounts();

      expect(result, isA<Failure<MoreMenuCounts>>());
      repository.invalidateCache();
    },
  );
}
