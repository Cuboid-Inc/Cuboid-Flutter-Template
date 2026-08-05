import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/features/more/data/business_profile_repository.dart';
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
