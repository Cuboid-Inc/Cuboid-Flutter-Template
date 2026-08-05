import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/theme/app_colors.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

enum SnackbarType { success, error, warning, info }

/// Design toast (Al Masar v3): navy pill floating above the bottom nav,
/// with multiple themed variants, auto-dismiss.
void setupSnackbarUi() {
  final snackbarService = locator<SnackbarService>();

  SnackbarConfig buildConfig({Color? iconBgColor, IconData? iconData}) {
    return SnackbarConfig(
      backgroundColor: AppColors.navy,
      textColor: Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 80),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      icon: iconData != null
          ? Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: iconBgColor ?? AppColors.success,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, size: 14, color: Colors.white),
            )
          : null,
      shouldIconPulse: true,
      boxShadows: const [
        BoxShadow(
          color: Color(0x66101828),
          offset: Offset(0, 16),
          blurRadius: 40,
        ),
      ],
      duration: const Duration(milliseconds: 2600),
      animationDuration: const Duration(milliseconds: 220),
    );
  }

  // Register default config: neutral/success (maintains fallback check badge)
  snackbarService.registerSnackbarConfig(
    buildConfig(
      iconBgColor: AppColors.success,
      iconData: CupertinoIcons.check_mark,
    ),
  );

  // Register custom variant configurations
  snackbarService.registerCustomSnackbarConfig(
    variant: SnackbarType.success,
    config: buildConfig(
      iconBgColor: AppColors.success,
      iconData: CupertinoIcons.check_mark,
    ),
  );

  snackbarService.registerCustomSnackbarConfig(
    variant: SnackbarType.error,
    config: buildConfig(
      iconBgColor: AppColors.danger,
      iconData: CupertinoIcons.xmark,
    ),
  );

  snackbarService.registerCustomSnackbarConfig(
    variant: SnackbarType.warning,
    config: buildConfig(
      iconBgColor: const Color(0xFFF59E0B),
      iconData: CupertinoIcons.exclamationmark_triangle,
    ),
  );

  snackbarService.registerCustomSnackbarConfig(
    variant: SnackbarType.info,
    config: buildConfig(
      iconBgColor: AppColors.primary,
      iconData: CupertinoIcons.info_circle,
    ),
  );
}

extension SnackbarServiceExtension on SnackbarService {
  void showSuccess(String message) {
    showCustomSnackBar(message: message, variant: SnackbarType.success);
  }

  void showError(String message) {
    showCustomSnackBar(message: message, variant: SnackbarType.error);
  }

  void showWarning(String message) {
    showCustomSnackBar(message: message, variant: SnackbarType.warning);
  }

  void showInfo(String message) {
    showCustomSnackBar(message: message, variant: SnackbarType.info);
  }
}
