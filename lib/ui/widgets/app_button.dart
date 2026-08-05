import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';

/// Full-width primary button with an optional loading spinner and compact variant support.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: compact
            ? const EdgeInsets.symmetric(vertical: 10, horizontal: 16)
            : const EdgeInsets.symmetric(vertical: s16),
        textStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: compact ? 13 : 15,
        ),
      ),
      onPressed: loading ? null : onPressed,
      child: Center(
        widthFactor: compact ? 1.0 : null,
        child: loading
            ? AppLoadingIndicator(spinerColor: AppColors.bg)
            : Text(label),
      ),
    );
  }
}

/// Full-width secondary (outline) button, e.g. "Cancel" actions, with compact variant support.
class AppOutlineButton extends StatelessWidget {
  const AppOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.primary,
    this.compact = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool compact;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        padding: compact
            ? const EdgeInsets.symmetric(vertical: 10, horizontal: 16)
            : const EdgeInsets.symmetric(vertical: s16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: TextStyle(fontWeight: FontWeight.w800),
      ),
      child: Center(
        widthFactor: compact ? 1.0 : null,
        child: loading
            ? AppLoadingIndicator()
            : Text(
                label,
                style: TextStyle(fontSize: compact ? 13 : 14, color: color),
              ),
      ),
    );
  }
}
