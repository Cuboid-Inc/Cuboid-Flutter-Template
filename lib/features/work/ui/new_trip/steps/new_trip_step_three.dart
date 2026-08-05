import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/new_trip_viewmodel.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/widgets/form_section_label.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/widgets/trip_total_card.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_combo_box.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_text_field.dart';
import 'package:cuboid_flutter_template/ui/widgets/extra_row.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NewTripStepThree extends StatelessWidget {
  const NewTripStepThree({super.key, required this.vm});

  final NewTripViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trip rate input
        AppTextField(
          label: 'Trip Rate',
          controller: vm.rate,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          hintText: 'AED 0.00',
        ),
        const SizedBox(height: 18),

        // Extra charges combo — shows unselected extras, allows adding custom
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AppComboBox<String>(
                label: 'add extra charges',
                value: null,
                items: vm.unselectedExtras,
                placeholder: 'Search route extras...',
                itemLabelBuilder: (name) => name,
                itemSubtitleBuilder: (name) =>
                    '+${Formatters.money(vm.extraRate(name))}',
                filterFn: (name, query) =>
                    name.toLowerCase().contains(query.toLowerCase()),
                onChanged: (name) {
                  if (name != null) {
                    final updated = List<String>.from(vm.extras)..add(name);
                    vm.selectExtras(updated);
                  }
                },
                addLabel: 'Add Custom Extra',
                onAddPressed: vm.openAddCustomExtraDialog,
              ),
            ),
            IconButton(
              onPressed: vm.openAddCustomExtraDialog,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                  AppColors.primary.withValues(alpha: .1),
                ),
              ),
              icon: const Icon(CupertinoIcons.add, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Selected extras with compact rows and clearly visible action buttons
        if (vm.extras.isNotEmpty) ...[
          const FormSectionLabel('SELECTED EXTRAS (TAP PENCIL TO EDIT)'),
          const SizedBox(height: 8),
          ListCard(
            child: Column(
              children: [
                for (var i = 0; i < vm.extras.length; i++) ...[
                  ExtraRow(
                    name: vm.extras[i],
                    amount: Formatters.money(vm.extraRate(vm.extras[i])),
                    onEdit: () => vm.openEditExtraRateDialog(vm.extras[i]),
                    onDelete: () {
                      final updated = List<String>.from(vm.extras)
                        ..remove(vm.extras[i]);
                      vm.selectExtras(updated);
                    },
                  ),
                  if (i < vm.extras.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Running total summary
        TripTotalCard(formattedTotal: Formatters.money(vm.total)),
      ],
    );
  }
}
