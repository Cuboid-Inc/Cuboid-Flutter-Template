import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/features/more/data/staff_member_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a staff member without access packs', () {
    final member = StaffMemberRow.fromRow({
      'id': 'member-1',
      'display_name': 'Aisha Khan',
      'email': 'aisha@example.com',
      'role': 'staff',
      'status': 'active',
    });

    expect(member.id, 'member-1');
    expect(member.name, 'Aisha Khan');
    expect(member.email, 'aisha@example.com');
    expect(member.role, StaffRole.staff);
    expect(member.status, StaffStatus.active);
    expect(member.accessPacks, isEmpty);
  });

  test('maps access packs into a set', () {
    final member = StaffMemberRow.fromRow({
      'id': 'member-2',
      'display_name': 'Omar Ali',
      'email': 'omar@example.com',
      'role': 'owner',
      'status': 'invited',
      'member_access_packs': [
        {'pack': 'operations'},
        {'pack': 'money'},
        {'pack': 'operations'},
      ],
    });

    expect(member.role, StaffRole.owner);
    expect(member.status, StaffStatus.invited);
    expect(member.accessPacks, {AccessPack.operations, AccessPack.money});
  });
}
