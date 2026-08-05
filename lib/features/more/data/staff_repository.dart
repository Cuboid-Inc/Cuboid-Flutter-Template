import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/core/supabase/supabase_guard.dart';
import 'package:cuboid_flutter_template/features/more/data/staff_member_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StaffRepository {
  Future<Result<List<StaffMember>>> fetchStaff(String tenantId) => guard(
    () async =>
        (await Supabase.instance.client
                .from('tenant_members')
                .select(
                  'id, display_name, email, role, status, '
                  'member_access_packs(pack)',
                )
                .eq('tenant_id', tenantId)
                .order('role')
                .order('display_name'))
            .map(StaffMemberRow.fromRow)
            .toList(),
  );

  Future<Result<StaffMember>> inviteStaff(StaffMember member) =>
      guard(() async {
        final response = await Supabase.instance.client.functions.invoke(
          'invite-staff',
          body: {
            'email': member.email,
            'displayName': member.name,
            'accessPacks': member.accessPacks
                .map((pack) => pack.toJson())
                .toList(),
          },
        );
        final data = response.data as Map<String, dynamic>;
        return StaffMember(
          id: data['id'] as String,
          name: member.name,
          email: member.email,
          accessPacks: member.accessPacks,
          status: StaffStatus.invited,
        );
      });
}
