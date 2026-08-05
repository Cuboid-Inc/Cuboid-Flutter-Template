import 'package:fleetgo/core/models/business_profile.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/more/data/business_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test(
    'profile operations return guard failures without Supabase config',
    () async {
      final repository = BusinessProfileRepository(MockAuthRepository());
      const profile = BusinessProfile(legalName: 'FleetGo');

      expect(
        await repository.fetchBusinessProfile(),
        isA<Failure<BusinessProfile>>(),
      );
      expect(
        await repository.updateBusinessProfile(profile),
        isA<Failure<BusinessProfile>>(),
      );
      repository.invalidateCache();
    },
  );
}
