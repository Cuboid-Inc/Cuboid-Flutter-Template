import 'package:cuboid_flutter_template/core/forms/form_validators.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/dialogs/add_edit_extra/add_edit_extra_dialog_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// A reusable iOS-style dialog for adding or editing an extra charge.
///
/// **Request data (optional `Map<String, dynamic>`):**
/// - `name`   — pre-fills the name field (edit mode)
/// - `amount` — pre-fills the amount field (edit mode)
///
/// **Response data (`Map<String, dynamic>`):**
/// - `name`   — String
/// - `amount` — double
class AddEditExtraDialog extends StackedView<AddEditExtraDialogModel> {
  const AddEditExtraDialog({
    super.key,
    required this.request,
    required this.completer,
  });

  final DialogRequest request;
  final Function(DialogResponse) completer;

  @override
  Widget builder(
    BuildContext context,
    AddEditExtraDialogModel viewModel,
    Widget? child,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: CupertinoColors.systemBackground,
            child: Form(
              key: viewModel.formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      children: [
                        Text(
                          viewModel.isEditing ? 'Edit Extra' : 'Add Extra',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          viewModel.isEditing
                              ? 'Update the rate for this extra charge.'
                              : 'Define a name and rate for the extra charge.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        _IosField(
                          controller: viewModel.nameController,
                          placeholder: 'Extra Name (e.g. Waiting Time)',
                          textCapitalization: TextCapitalization.words,
                          enabled: !viewModel.isEditing,
                          validator: (value) => FormValidators.required(
                            value,
                            label: 'Extra name',
                          ),
                        ),
                        const SizedBox(height: 10),
                        _IosField(
                          controller: viewModel.amountController,
                          placeholder: 'Amount (AED)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: FormValidators.money,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _DialogAction(
                            label: 'Cancel',
                            onTap: viewModel.cancel,
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: _DialogAction(
                            label: viewModel.isEditing ? 'Save' : 'Add',
                            isDefault: true,
                            onTap: () {
                              if (viewModel.formKey.currentState?.validate() ==
                                  true) {
                                viewModel.submit();
                              }
                            },
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
      ),
    );
  }

  @override
  AddEditExtraDialogModel viewModelBuilder(BuildContext context) =>
      AddEditExtraDialogModel(completer: completer, request: request);
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _IosField extends StatelessWidget {
  const _IosField({
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.validator,
  });

  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? CupertinoColors.systemGrey6
            : CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: placeholder,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          hintStyle: const TextStyle(
            fontSize: 15,
            color: CupertinoColors.placeholderText,
          ),
          errorStyle: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.destructiveRed,
          ),
        ),
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        enabled: enabled,
        validator: validator,
        style: const TextStyle(fontSize: 15, color: CupertinoColors.label),
        cursorColor: CupertinoColors.activeBlue,
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.onTap,
    this.isDefault = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
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
            color: isDefault
                ? AppColors.primary
                : CupertinoColors.secondaryLabel,
          ),
        ),
      ),
    );
  }
}
