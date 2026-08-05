import 'package:cuboid_flutter_template/core/theme/app_colors.dart';
import 'package:cuboid_flutter_template/core/theme/ui_helpers.dart';
import 'package:flutter/material.dart';

enum AppLoadingIndicatorVariant { fullScreen, inline, overlay }

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.variant = AppLoadingIndicatorVariant.inline,
    this.message,
    this.spinerColor,
  });

  final AppLoadingIndicatorVariant variant;
  final String? message;
  final Color? spinerColor;

  Widget get spinner => SizedBox(
    height: 18,
    width: 18,
    child: CircularProgressIndicator(
      strokeWidth: 2.8,
      valueColor: AlwaysStoppedAnimation(spinerColor ?? AppColors.primary),
    ),
  );

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppLoadingIndicatorVariant.fullScreen:
        return Scaffold(
          backgroundColor: AppColors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                spinner,
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      case AppLoadingIndicatorVariant.overlay:
        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                spinner,
                if (message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    message!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      case AppLoadingIndicatorVariant.inline:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                spinner,
                if (message != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    message!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }
}
