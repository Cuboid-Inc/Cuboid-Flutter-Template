import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/features/work/ui/monthly_work/monthly_work_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_combo_box.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_date_time_picker.dart';
import 'package:flutter/material.dart';

class MonthlyWorkStepOne extends StatelessWidget {
  const MonthlyWorkStepOne({super.key, required this.vm});

  final MonthlyWorkViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppComboBox<Agreement>.async(
          label: 'monthly agreement',
          value: vm.selectedAgreement,
          placeholder: 'Tap to select agreement...',
          itemLabelBuilder: (agreement) =>
              '${agreement.reference} · ${agreement.name}',
          itemSubtitleBuilder: (agreement) =>
              '${Formatters.money(agreement.baseRate)} / month · Terms: ${agreement.paymentTerms.label}',
          fetchPage: vm.fetchMonthlyAgreementsPage,
          onChanged: vm.selectAgreement,
        ),
        const SizedBox(height: 18),
        AppDateTimePicker(
          label: 'Service date',
          value: vm.serviceDate,
          mode: AppDateTimePickerMode.date,
          onChanged: vm.setServiceDate,
        ),
      ],
    );
  }
}
