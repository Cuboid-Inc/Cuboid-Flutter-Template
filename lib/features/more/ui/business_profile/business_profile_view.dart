import 'dart:io';

import 'package:fleetgo/core/forms/form_validators.dart';
import 'package:fleetgo/features/more/ui/business_profile/business_profile_viewmodel.dart';
import 'package:fleetgo/features/more/ui/business_profile/widgets/brand_color_picker.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_bar_ios.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/ui/widgets/app_loading_indicator.dart';
import 'package:fleetgo/ui/widgets/app_text_field.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:fleetgo/ui/widgets/section_label.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class BusinessProfileView extends StackedView<BusinessProfileViewModel> {
  const BusinessProfileView({super.key});

  @override
  void onViewModelReady(BusinessProfileViewModel viewModel) => viewModel.init();

  @override
  BusinessProfileViewModel viewModelBuilder(BuildContext context) =>
      BusinessProfileViewModel();

  @override
  Widget builder(
    BuildContext context,
    BusinessProfileViewModel vm,
    Widget? child,
  ) => Scaffold(
    appBar: AppBarIOS(title: 'Business & branding'),
    body: vm.isBusy
        ? const AppLoadingIndicator(message: 'Loading business profile')
        : Form(
            key: vm.formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(s16, s16, s16, 100),
              children: [
                const SectionLabel('Identity'),
                const SizedBox(height: s8),
                ListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: 'Legal business name',
                        controller: vm.legalNameController,
                        validator: (value) => FormValidators.required(
                          value,
                          label: 'Legal business name',
                        ),
                      ),
                      const SizedBox(height: s12),
                      AppTextField(
                        label: 'TRN',
                        controller: vm.trnController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: s12),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: vm.toggleMoreIdentityDetails,
                        child: Row(
                          children: [
                            const Text(
                              'More details',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(width: s4),
                            Icon(
                              vm.showMoreIdentityDetails
                                  ? CupertinoIcons.chevron_up
                                  : CupertinoIcons.chevron_down,
                              size: 14,
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                      if (vm.showMoreIdentityDetails) ...[
                        const SizedBox(height: s12),
                        AppTextField(
                          label: 'Arabic legal name (optional)',
                          controller: vm.arabicLegalNameController,
                        ),
                        const SizedBox(height: s12),
                        AppTextField(
                          label: 'Trade licence number',
                          controller: vm.tradeLicenceController,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: s16),
                const SectionLabel('Contact'),
                const SizedBox(height: s8),
                ListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'City',
                              controller: vm.cityController,
                            ),
                          ),
                          const SizedBox(width: s12),
                          Expanded(
                            child: AppTextField(
                              label: 'Address',
                              controller: vm.addressController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: s12),
                      AppTextField(
                        label: 'Phone',
                        controller: vm.phoneController,
                        keyboardType: TextInputType.phone,
                        validator: FormValidators.phone,
                      ),
                      const SizedBox(height: s12),
                      AppTextField(
                        label: 'Email',
                        controller: vm.emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            FormValidators.email(value, optional: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: s16),
                const SectionLabel('Invoicing'),
                const SizedBox(height: s8),
                ListCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Currency',
                          controller: TextEditingController(text: vm.currency),
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: s12),
                      Expanded(
                        child: AppTextField(
                          label: 'Invoice number prefix',
                          controller: vm.invoicePrefixController,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: s16),
                const SectionLabel('Letterhead'),
                const SizedBox(height: s8),
                ListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CupertinoSlidingSegmentedControl<bool>(
                        groupValue: vm.useCustomLetterhead,
                        onValueChanged: (value) =>
                            vm.selectLetterheadMode(value ?? false),
                        children: const {
                          false: Padding(
                            padding: EdgeInsets.symmetric(vertical: s8),
                            child: Text('System header'),
                          ),
                          true: Padding(
                            padding: EdgeInsets.symmetric(vertical: s8),
                            child: Text('Custom letterhead'),
                          ),
                        },
                      ),
                      const SizedBox(height: s16),
                      if (!vm.useCustomLetterhead) ...[
                        const Text(
                          'ACCENT COLOR',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.06,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: s8),
                        BrandColorPicker(
                          value: vm.brandColor,
                          onChanged: vm.selectBrandColor,
                        ),
                        const SizedBox(height: s16),
                        AppTextField(
                          label: 'Footer note',
                          controller: vm.footerController,
                          hintText: 'Shown on every PDF footer',
                          maxLength:
                              BusinessProfileViewModel.footerNoteMaxLength,
                        ),
                        const SizedBox(height: s12),
                        AppTextField(
                          label: 'Payment instructions',
                          controller: vm.paymentInstructionsController,
                          hintText: 'e.g. bank details for transfers',
                          maxLength:
                              BusinessProfileViewModel.footerNoteMaxLength,
                        ),
                      ] else ...[
                        if (vm.letterheadPath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(radiusSm),
                            child: Image.file(
                              File(vm.letterheadPath!),
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 120,
                                    alignment: Alignment.center,
                                    color: AppColors.dangerBg,
                                    child: const Text(
                                      'Could not load this letterhead file',
                                      style: TextStyle(
                                        color: AppColors.dangerDark,
                                      ),
                                    ),
                                  ),
                            ),
                          )
                        else
                          Container(
                            height: 120,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radiusSm),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              'No letterhead uploaded',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        if (vm.letterheadIsLowRes) ...[
                          const SizedBox(height: s12),
                          Container(
                            padding: const EdgeInsets.all(s12),
                            decoration: BoxDecoration(
                              color: AppColors.warningBg,
                              borderRadius: BorderRadius.circular(radiusSm),
                            ),
                            child: const Text(
                              'This image is lower resolution than recommended — '
                              'text may look blurry when printed.',
                              style: TextStyle(
                                color: AppColors.warningDark,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: s12),
                        Row(
                          children: [
                            Expanded(
                              child: AppOutlineButton(
                                label: vm.letterheadPath == null
                                    ? 'Upload image or PDF'
                                    : 'Replace',
                                compact: true,
                                loading: vm.busy(
                                  BusinessProfileBusy.letterhead,
                                ),
                                onPressed: vm.pickLetterhead,
                              ),
                            ),
                            if (vm.letterheadPath != null) ...[
                              const SizedBox(width: s12),
                              Expanded(
                                child: AppOutlineButton(
                                  label: 'Remove',
                                  compact: true,
                                  color: AppColors.danger,
                                  loading: vm.busy(
                                    BusinessProfileBusy.letterhead,
                                  ),
                                  onPressed: vm.removeLetterhead,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (vm.letterheadPath != null) ...[
                          const SizedBox(height: s16),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Top margin (mm)',
                                  controller: vm.letterheadMarginTopController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) =>
                                      FormValidators.numberRange(
                                        value,
                                        label: 'Top margin',
                                        min: 0,
                                        max: 100,
                                      ),
                                ),
                              ),
                              const SizedBox(width: s12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Bottom margin (mm)',
                                  controller:
                                      vm.letterheadMarginBottomController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) =>
                                      FormValidators.numberRange(
                                        value,
                                        label: 'Bottom margin',
                                        min: 0,
                                        max: 100,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: s12),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Left margin (mm)',
                                  controller: vm.letterheadMarginLeftController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) =>
                                      FormValidators.numberRange(
                                        value,
                                        label: 'Left margin',
                                        min: 0,
                                        max: 100,
                                      ),
                                ),
                              ),
                              const SizedBox(width: s12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Right margin (mm)',
                                  controller:
                                      vm.letterheadMarginRightController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) =>
                                      FormValidators.numberRange(
                                        value,
                                        label: 'Right margin',
                                        min: 0,
                                        max: 100,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: s16),
                          AppButton(
                            label: 'Preview with sample content',
                            compact: true,
                            onPressed: () {
                              if (vm.formKey.currentState?.validate() == true) {
                                vm.previewLetterhead();
                              }
                            },
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: s24),
                AppButton(
                  label: 'Save changes',
                  loading: vm.busy(BusinessProfileBusy.save),
                  onPressed: () {
                    if (vm.formKey.currentState?.validate() == true) {
                      vm.save();
                    }
                  },
                ),
              ],
            ),
          ),
  );
}
