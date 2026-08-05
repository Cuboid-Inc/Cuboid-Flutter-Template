import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/business_profile.dart';

extension StaffMemberRow on StaffMember {
  static StaffMember fromRow(Map<String, dynamic> row) {
    final packRows = row['member_access_packs'] as List<dynamic>? ?? const [];
    return StaffMember(
      id: row['id'] as String,
      name: row['display_name'] as String,
      email: row['email'] as String,
      role: enumFromJson(row['role'] as String, StaffRole.values),
      status: enumFromJson(row['status'] as String, StaffStatus.values),
      accessPacks: packRows
          .map((value) => (value as Map<String, dynamic>)['pack'] as String)
          .map((value) => enumFromJson(value, AccessPack.values))
          .toSet(),
    );
  }
}
