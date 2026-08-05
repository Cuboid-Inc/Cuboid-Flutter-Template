import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';

extension AuthAccessRow on AuthAccess {
  static AuthAccess fromRow(Map<String, dynamic> row) {
    final tenant = row['tenants'] as Map<String, dynamic>?;
    final packRows = row['member_access_packs'] as List<dynamic>? ?? const [];
    return AuthAccess(
      memberId: row['id'] as String,
      tenantId: row['tenant_id'] as String,
      tenantName: tenant?['name'] as String? ?? '',
      email: row['email'] as String,
      displayName: row['display_name'] as String,
      role: enumFromJson(row['role'] as String, StaffRole.values),
      status: enumFromJson(row['status'] as String, MembershipStatus.values),
      accessPacks: packRows
          .map((value) => (value as Map<String, dynamic>)['pack'] as String)
          .map((value) => enumFromJson(value, AccessPack.values))
          .toSet(),
    );
  }
}
