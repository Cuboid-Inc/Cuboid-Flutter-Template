import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/ui/bottom_sheets/period/period_sheet_model.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/widgets/app_button.dart';
import 'package:fleetgo/ui/widgets/demo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class PeriodSheet extends StackedView<PeriodSheetModel> {
  const PeriodSheet({
    super.key,
    required this.completer,
    required this.request,
  });

  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  @override
  void onViewModelReady(PeriodSheetModel viewModel) => viewModel.init();

  @override
  Widget builder(
    BuildContext context,
    PeriodSheetModel viewModel,
    Widget? child,
  ) => DemoSheet(
    title: 'History & period',
    subtitle: 'Applies to Home totals and all reports',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('QUICK', style: _periodLabel),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _choice(viewModel, 'This month', Period.thisMonth()),
            _choice(viewModel, 'Last month', Period.lastMonth()),
            _choice(viewModel, 'This year', Period.year(DateTime.now().year)),
            if (viewModel.years.length > 1)
              _choice(
                viewModel,
                'Last year',
                Period.year(DateTime.now().year - 1),
              ),
            ChoiceChip(
              label: Text(
                viewModel.isCustom
                    ? '${Formatters.date(viewModel.selected.start)} – ${Formatters.date(viewModel.selected.end)}'
                    : 'Custom',
              ),
              selected: viewModel.isCustom,
              onSelected: (_) => _pickCustom(context, viewModel),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('YEAR', style: _periodLabel),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final year in viewModel.years)
              _choice(viewModel, '$year', Period.year(year)),
          ],
        ),
        const SizedBox(height: 16),
        Text('MONTH · ${viewModel.selected.start.year}', style: _periodLabel),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var month = 1; month <= viewModel.maxMonth; month++)
              _choice(
                viewModel,
                const [
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Jul',
                  'Aug',
                  'Sep',
                  'Oct',
                  'Nov',
                  'Dec',
                ][month - 1],
                Period.month(viewModel.selected.start.year, month),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: AppOutlineButton(
                label: 'Reset',
                onPressed: viewModel.reset,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: AppButton(
                label: 'Use selected period',
                onPressed: viewModel.submit,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _pickCustom(
    BuildContext context,
    PeriodSheetModel viewModel,
  ) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(viewModel.years.last),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: viewModel.selected.start,
        end: viewModel.selected.end.isAfter(now) ? now : viewModel.selected.end,
      ),
    );
    if (range == null) return;
    viewModel.select(
      Period(
        start: DateTime(range.start.year, range.start.month, range.start.day),
        end: DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
          59,
        ),
      ),
    );
  }

  ChoiceChip _choice(PeriodSheetModel viewModel, String label, Period period) =>
      ChoiceChip(
        label: Text(label),
        selected:
            viewModel.selected.start == period.start &&
            viewModel.selected.end == period.end,
        onSelected: (_) => viewModel.select(period),
      );

  @override
  PeriodSheetModel viewModelBuilder(BuildContext context) =>
      PeriodSheetModel(completer: completer!, request: request);
}

const _periodLabel = TextStyle(
  fontSize: 11.5,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.6,
  color: AppColors.muted,
);
