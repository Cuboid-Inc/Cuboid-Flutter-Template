import 'package:cuboid_flutter_template/core/theme/app_colors.dart';
import 'package:cuboid_flutter_template/core/theme/ui_helpers.dart';
import 'package:cuboid_flutter_template/shared/widgets/app_loading_indicator.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

class DemoSheet extends StatelessWidget {
  const DemoSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.onClose,
    this.busy = false,
    this.loadingMessage,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onClose;
  final bool busy;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    final maxH = dheight * 0.92;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(s16, s8, s16, s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(radiusPill),
                ),
              ),
            ),
            const SizedBox(height: s16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: s4),
                          child: Text(
                            subtitle!,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose ?? () => Navigator.pop(context),
                  icon: const Icon(CupertinoIcons.xmark),
                ),
              ],
            ),
            const SizedBox(height: s16),
            Flexible(
              child: Stack(
                children: [
                  IgnorePointer(ignoring: busy, child: child),
                  if (busy)
                    AppLoadingIndicator(
                      variant: AppLoadingIndicatorVariant.overlay,
                      message: loadingMessage,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
