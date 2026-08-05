import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/features/work/ui/monthly_work/monthly_work_viewmodel.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/widgets/form_section_label.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/widgets/trip_total_card.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_dropdown.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_text_field.dart';
import 'package:cuboid_flutter_template/ui/widgets/extra_row.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:flutter/material.dart';

class MonthlyWorkStepTwo extends StatefulWidget {
  const MonthlyWorkStepTwo({super.key, required this.vm});

  final MonthlyWorkViewModel vm;

  @override
  State<MonthlyWorkStepTwo> createState() => _MonthlyWorkStepTwoState();
}

class _MonthlyWorkStepTwoState extends State<MonthlyWorkStepTwo> {
  final _formKey = GlobalKey<FormState>();
  final _customName = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _rate = TextEditingController();
  MonthlyExtraType _type = MonthlyExtraType.extraDay;

  @override
  void initState() {
    super.initState();
    _customName.addListener(_setDefaultRate);
    _setDefaultRate();
  }

  @override
  void dispose() {
    _customName.removeListener(_setDefaultRate);
    _customName.dispose();
    _quantity.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _setDefaultRate() {
    _rate.text = Formatters.rawMoney(
      widget.vm.defaultRateFor(_type, customName: _customName.text),
    );
  }

  void _selectType(MonthlyExtraType? value) {
    if (value == null) return;
    setState(() => _type = value);
    _setDefaultRate();
  }

  void _addCharge() {
    if (_formKey.currentState?.validate() != true) return;
    final rate = Formatters.parseMoney(_rate.text);
    if (rate == null) return;
    widget.vm.addCharge(
      _type,
      quantity: int.parse(_quantity.text),
      rate: rate,
      customName: _customName.text,
    );
    setState(() {
      _type = MonthlyExtraType.extraDay;
      _customName.clear();
      _quantity.text = '1';
      _setDefaultRate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (vm.charges.isNotEmpty) ...[
          const FormSectionLabel('CURRENT CHARGES'),
          ListCard(
            child: Column(
              children: [
                for (var index = 0; index < vm.charges.length; index++) ...[
                  ExtraRow(
                    name:
                        '${vm.charges[index].name} × ${vm.charges[index].quantity}',
                    amount: Formatters.money(vm.charges[index].lineTotal),
                    onEdit: () {},
                    onDelete: () => vm.removeCharge(index),
                  ),
                  if (index < vm.charges.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        const FormSectionLabel('ADD CHARGE'),
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppDropdown<MonthlyExtraType>(
                label: 'Charge type',
                value: _type,
                items: MonthlyExtraType.values,
                itemLabelBuilder: (type) => type.label,
                onChanged: _selectType,
              ),
              if (_type == MonthlyExtraType.custom) ...[
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Charge name',
                  controller: _customName,
                  hintText: 'e.g. Crane hire',
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? 'Enter a charge name'
                      : null,
                ),
              ],
              const SizedBox(height: 12),
              AppTextField(
                label: 'Quantity',
                controller: _quantity,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final quantity = int.tryParse(value ?? '');
                  return quantity == null || quantity < 1
                      ? 'Enter a quantity of 1 or more'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Rate',
                controller: _rate,
                hintText: 'AED 0.00',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final rate = Formatters.parseMoney(value ?? '');
                  return rate == null || rate < 0 ? 'Enter a valid rate' : null;
                },
              ),
              const SizedBox(height: 16),
              AppOutlineButton(
                label: 'Add charge',
                compact: true,
                onPressed: _addCharge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TripTotalCard(formattedTotal: Formatters.money(vm.total)),
      ],
    );
  }
}
