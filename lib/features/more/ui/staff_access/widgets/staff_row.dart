import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:flutter/cupertino.dart';

class StaffRow extends StatelessWidget {
  const StaffRow({super.key, required this.member, required this.packsLabel});

  final StaffMember member;
  final String Function(StaffMember) packsLabel;

  bool get _isOwner => member.role == StaffRole.owner;

  @override
  Widget build(BuildContext context) {
    final tint = _isOwner ? AppColors.primary : AppColors.success;
    final tintBg = _isOwner ? AppColors.chipBg : AppColors.successBg;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: s16 - 2, vertical: s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tintBg,
              borderRadius: BorderRadius.circular(radiusSm),
            ),
            child: Icon(
              _isOwner
                  ? CupertinoIcons.person_crop_circle_fill_badge_checkmark
                  : CupertinoIcons.person_fill,
              color: tint,
              size: 18,
            ),
          ),
          const SizedBox(width: s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  member.email,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  packsLabel(member),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            member.status == StaffStatus.invited
                ? 'Invited'
                : member.role.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
