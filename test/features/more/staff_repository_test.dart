import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/business_profile.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/more/data/staff_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('staff reads return guard failures without Supabase config', () async {
    final repository = StaffRepository();
    final member = const StaffMember(
      id: 'member',
      name: 'Staff',
      email: 'staff@example.com',
      accessPacks: {AccessPack.operations},
    );

    expect(
      await repository.fetchStaff('tenant'),
      isA<Failure<List<StaffMember>>>(),
    );
    expect(await repository.inviteStaff(member), isA<Failure<StaffMember>>());
  });
}
