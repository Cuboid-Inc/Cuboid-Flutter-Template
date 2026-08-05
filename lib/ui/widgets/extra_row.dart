import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A labelled row representing a single extra charge.
///
/// Displays the extra [name] on the left, the formatted [amount] in primary
/// colour, and pencil/trash circle-action buttons on the right.
///
/// Used in both the route-rate form sheet and the new-trip step-three screen.
class ExtraRow extends StatelessWidget {
  const ExtraRow({
    super.key,
    required this.name,
    required this.amount,
    required this.onEdit,
    required this.onDelete,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  final String name;
  final String amount;
  final EdgeInsetsGeometry padding;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          CircleAction(
            icon: CupertinoIcons.pencil,
            color: AppColors.primary,
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          CircleAction(
            icon: CupertinoIcons.trash,
            color: Colors.redAccent,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

/// A small circular icon button used as an inline action (e.g. edit / delete).
class CircleAction extends StatelessWidget {
  const CircleAction({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
