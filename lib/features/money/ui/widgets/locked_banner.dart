import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:flutter/cupertino.dart';

/// Banner shown on invoice/settlement detail screens once the document
/// is paid (locked) or voided.
class LockedBanner extends StatelessWidget {
  const LockedBanner({super.key, required this.paid, required this.message});

  final bool paid;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = paid ? AppColors.success : AppColors.muted;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            paid
                ? CupertinoIcons.check_mark_circled
                : CupertinoIcons.xmark_circle,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
