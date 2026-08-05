import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/forms/form_validators.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/invite_staff_form/invite_staff_form_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_text_field.dart';
import 'package:cuboid_flutter_template/ui/widgets/chip_selector.dart';
import 'package:cuboid_flutter_template/ui/widgets/demo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class InviteStaffFormSheet extends StackedView<InviteStaffFormSheetModel> {
  const InviteStaffFormSheet({
    super.key,
    required this.completer,
    required this.request,
  });

  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  @override
  Widget builder(
    BuildContext context,
    InviteStaffFormSheetModel viewModel,
    Widget? child,
  ) => DemoSheet(
    title: 'Invite teammate',
    subtitle: 'Send scoped access to the sections they need',
    child: SingleChildScrollView(
      child: Form(
        key: viewModel.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Name',
              controller: viewModel.nameController,
              validator: (value) =>
                  FormValidators.required(value, label: 'Name'),
            ),
            const SizedBox(height: s12),
            AppTextField(
              label: 'Email',
              controller: viewModel.emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              autocorrect: false,
              validator: FormValidators.email,
            ),
            const SizedBox(height: s12),
            const Text('ACCESS PACKS', style: _label),
            const SizedBox(height: s8),
            FormField<List<AccessPack>>(
              initialValue: viewModel.selectedPacks,
              validator: (packs) => packs == null || packs.isEmpty
                  ? 'Select at least one access pack'
                  : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChipSelector<AccessPack>(
                    items: AccessPack.values,
                    selected: viewModel.selectedPacks,
                    labelBuilder: (pack) => pack.label,
                    multiSelect: true,
                    onChanged: (packs) {
                      field.didChange(packs);
                      viewModel.selectPacks(packs);
                    },
                  ),
                  if (field.errorText case final error?)
                    Text(
                      error,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: s24),
            AppButton(
              label: 'Send invitation',
              onPressed: () {
                if (viewModel.formKey.currentState?.validate() == true) {
                  viewModel.submit();
                }
              },
            ),
          ],
        ),
      ),
    ),
  );

  @override
  InviteStaffFormSheetModel viewModelBuilder(BuildContext context) =>
      InviteStaffFormSheetModel(completer: completer!, request: request);
}

const _label = TextStyle(
  fontSize: 11.5,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.06,
  color: Color(0xFF64748B),
);
