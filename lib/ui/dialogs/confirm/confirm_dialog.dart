import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/dialogs/confirm/confirm_dialog_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// iOS-style confirmation dialog — wider card, no square-center look.
class ConfirmDialog extends StackedView<ConfirmDialogModel> {
  const ConfirmDialog({
    super.key,
    required this.request,
    required this.completer,
  });

  final DialogRequest request;
  final Function(DialogResponse) completer;

  @override
  Widget builder(
    BuildContext context,
    ConfirmDialogModel viewModel,
    Widget? child,
  ) {
    final bool isDangerous =
        (request.mainButtonTitle ?? '').toLowerCase().contains('cancel') ||
        (request.mainButtonTitle ?? '').toLowerCase().contains('delete') ||
        (request.mainButtonTitle ?? '').toLowerCase().contains('remove');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: CupertinoColors.systemBackground,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Content ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    children: [
                      Text(
                        request.title ?? 'Confirm action',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      if ((request.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          request.description!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Divider + Action buttons ─────────────────────────────
                const Divider(height: 1, color: AppColors.border),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _DialogAction(
                          label: request.secondaryButtonTitle ?? 'No',
                          onTap: viewModel.cancel,
                        ),
                      ),
                      const VerticalDivider(width: 1, color: AppColors.border),
                      Expanded(
                        child: _DialogAction(
                          label: request.mainButtonTitle ?? 'Yes',
                          isDefault: true,
                          isDestructive: isDangerous,
                          onTap: viewModel.confirm,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  ConfirmDialogModel viewModelBuilder(BuildContext context) =>
      ConfirmDialogModel(completer: completer);
}

// ── Shared action button ──────────────────────────────────────────────────────

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.onTap,
    this.isDefault = false,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDefault;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color color = isDestructive
        ? AppColors.danger
        : isDefault
        ? AppColors.primary
        : CupertinoColors.secondaryLabel;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: isDefault ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
        ),
      ),
    );
  }
}
