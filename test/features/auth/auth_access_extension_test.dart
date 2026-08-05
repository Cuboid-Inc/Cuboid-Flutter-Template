import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/features/auth/data/auth_access_extension.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps auth access with tenant and access packs', () {
    final access = AuthAccessRow.fromRow({
      'id': 'member-1',
      'tenant_id': 'tenant-1',
      'tenants': {'name': 'FleetGo'},
      'email': 'owner@example.com',
      'display_name': 'Owner',
      'role': 'owner',
      'status': 'active',
      'member_access_packs': [
        {'pack': 'operations'},
        {'pack': 'reports'},
        {'pack': 'operations'},
      ],
    });

    expect(access.memberId, 'member-1');
    expect(access.tenantName, 'FleetGo');
    expect(access.role, StaffRole.owner);
    expect(access.status, MembershipStatus.active);
    expect(access.accessPacks, {AccessPack.operations, AccessPack.reports});
    expect(access.isOwner, isTrue);
  });

  test('uses empty tenant name and packs when joined rows are absent', () {
    final access = AuthAccessRow.fromRow({
      'id': 'member-2',
      'tenant_id': 'tenant-2',
      'tenants': null,
      'email': 'staff@example.com',
      'display_name': 'Staff',
      'role': 'staff',
      'status': 'suspended',
    });

    expect(access.tenantName, isEmpty);
    expect(access.accessPacks, isEmpty);
    expect(access.isOwner, isFalse);
  });
}
