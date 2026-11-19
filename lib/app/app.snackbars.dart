/// Snackbar styling for [MessageService] -- colors, icons, and the actual
/// [SnackBar] builder for each [SnackbarType]. Kept separate from
/// `message_service.dart` the same way `app.router.dart`'s route table is
/// kept separate from `NavigationService`: this file is pure styling/markup,
/// `message_service.dart` is the no-`BuildContext` API surface view models
/// call.
library;

import 'package:cuboid_flutter_template/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// The four message severities [MessageService] supports.
enum SnackbarType { error, success, info, warning }

class _SnackbarStyle {
  const _SnackbarStyle({
    required this.backgroundColor,
    required this.icon,
    required this.defaultTitle,
  });

  final Color backgroundColor;
  final IconData icon;
  final String defaultTitle;
}

const _styles = <SnackbarType, _SnackbarStyle>{
  SnackbarType.error: _SnackbarStyle(
    backgroundColor: AppColors.danger,
    icon: Icons.error_outline,
    defaultTitle: 'Error',
  ),
  SnackbarType.success: _SnackbarStyle(
    backgroundColor: AppColors.success,
    icon: Icons.check_circle_outline,
    defaultTitle: 'Success',
  ),
  SnackbarType.info: _SnackbarStyle(
    backgroundColor: AppColors.primary,
    icon: Icons.info_outline,
    defaultTitle: 'Info',
  ),
  SnackbarType.warning: _SnackbarStyle(
    backgroundColor: AppColors.warning,
    icon: Icons.warning_amber_outlined,
    defaultTitle: 'Warning',
  ),
};

/// Builds the floating, rounded [SnackBar] [MessageService] shows for
/// [type]. [title] falls back to a severity-appropriate default (e.g.
/// `'Error'`) when omitted.
SnackBar buildAppSnackBar({
  required SnackbarType type,
  required String message,
  String? title,
  Duration duration = const Duration(seconds: 3),
}) {
  final style = _styles[type]!;
  final resolvedTitle = title ?? style.defaultTitle;

  return SnackBar(
    backgroundColor: style.backgroundColor,
    duration: duration,
    behavior: SnackBarBehavior.floating,
    dismissDirection: DismissDirection.horizontal,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    content: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(style.icon, color: AppColors.white, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolvedTitle,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: const TextStyle(color: AppColors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
