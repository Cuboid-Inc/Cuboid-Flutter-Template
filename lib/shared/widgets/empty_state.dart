import 'package:nemara_homes/core/theme/app_colors.dart';
import 'package:nemara_homes/core/theme/ui_helpers.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = CupertinoIcons.archivebox,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.iconColor,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color? iconColor;
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(compact ? s16 : s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 32 : 42,
            color: iconColor ?? AppColors.mutedLight,
          ),
          SizedBox(height: compact ? s8 : s12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (subtitle != null)
            Padding(
              padding: EdgeInsets.only(top: compact ? s4 : s8),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          if (actionLabel != null && onAction != null)
            Padding(
              padding: const EdgeInsets.only(top: s12),
              child: TextButton.icon(
                onPressed: onAction,
                icon: actionIcon == null
                    ? const SizedBox.shrink()
                    : Icon(actionIcon),
                label: Text(actionLabel!),
              ),
            ),
        ],
      ),
    ),
  );
}
