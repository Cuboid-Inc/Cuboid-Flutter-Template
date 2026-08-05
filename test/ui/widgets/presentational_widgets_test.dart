import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/errors/failures.dart';
import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:cuboid_flutter_template/core/errors/result.dart';
import 'package:cuboid_flutter_template/shared/widgets/app_combo_box.dart';
import 'package:cuboid_flutter_template/shared/widgets/app_date_time_picker.dart';
import 'package:cuboid_flutter_template/shared/widgets/app_dropdown.dart';
import 'package:cuboid_flutter_template/shared/widgets/app_loading_indicator.dart';
import 'package:cuboid_flutter_template/shared/widgets/chip_selector.dart';
import 'package:cuboid_flutter_template/shared/widgets/demo_sheet.dart';
import 'package:cuboid_flutter_template/shared/widgets/detail_row.dart';
import 'package:cuboid_flutter_template/shared/widgets/extra_row.dart';
import 'package:cuboid_flutter_template/shared/widgets/financial_line_tile.dart';
import 'package:cuboid_flutter_template/shared/widgets/list_card.dart';
import 'package:cuboid_flutter_template/shared/widgets/paginated_list/paginated_list_view.dart';
import 'package:cuboid_flutter_template/shared/widgets/paginated_list/pagination_controller.dart';
import 'package:cuboid_flutter_template/shared/widgets/segmented_toggle.dart';
import 'package:cuboid_flutter_template/shared/widgets/status_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('ListCard renders and handles taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      app(
        ListCard(onTap: () => tapped = true, child: const Text('Card content')),
      ),
    );

    expect(find.text('Card content'), findsOneWidget);
    await tester.tap(find.text('Card content'));
    expect(tapped, isTrue);
  });

  testWidgets('DetailRow renders its label and value', (tester) async {
    await tester.pumpWidget(app(const DetailRow(label: 'Phone', value: '123')));
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
  });

  testWidgets('FinancialLineTile includes discount only when positive', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Column(
          children: [
            FinancialLineTile(
              description: 'Fuel',
              quantity: '2 L',
              unitPrice: 10,
              discount: 1,
              vatRate: 5,
              net: 19,
              gross: 19.95,
            ),
            FinancialLineTile(
              description: 'Toll',
              quantity: '1 trip',
              unitPrice: 4,
              discount: 0,
              vatRate: 0,
              net: 4,
              gross: 4,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Fuel'), findsOneWidget);
    expect(
      find.text('2 L × 10.00 · Disc. 1.00 · VAT 5% · Net 19.00'),
      findsOneWidget,
    );
    expect(find.text('1 trip × 4.00 · VAT 0% · Net 4.00'), findsOneWidget);
    expect(find.text('19.95'), findsOneWidget);
  });

  testWidgets('StatusChip factories render each status style', (tester) async {
    await tester.pumpWidget(
      app(
        Wrap(
          children: [
            StatusChip.success('Success'),
            StatusChip.warning('Warning'),
            StatusChip.danger('Danger'),
            StatusChip.info('Info'),
            StatusChip.neutral('Neutral'),
          ],
        ),
      ),
    );

    for (final label in ['Success', 'Warning', 'Danger', 'Info', 'Neutral']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('ChipSelector handles single and multi selection', (
    tester,
  ) async {
    List<int>? single;
    await tester.pumpWidget(
      app(
        ChipSelector<int>(
          items: const [1, 2],
          selected: const [],
          labelBuilder: (value) => 'Item $value',
          onChanged: (value) => single = value,
        ),
      ),
    );
    await tester.tap(find.text('Item 2'));
    expect(single, [2]);

    List<int>? multi;
    await tester.pumpWidget(
      app(
        ChipSelector<int>(
          items: const [1, 2],
          selected: const [1],
          multiSelect: true,
          onChanged: (value) => multi = value,
        ),
      ),
    );
    await tester.tap(find.text('1'));
    expect(multi, isEmpty);
  });

  testWidgets('SegmentedToggle calls back for a tapped value', (tester) async {
    int? selected;
    await tester.pumpWidget(
      app(
        SegmentedToggle<int>(
          values: const [1, 2],
          value: 1,
          labelBuilder: (value) => 'Option $value',
          onChanged: (value) => selected = value,
        ),
      ),
    );
    expect(find.text('Option 1'), findsOneWidget);
    await tester.tap(find.text('Option 2'));
    expect(selected, 2);
  });

  testWidgets('AppDropdown renders hint and selects an item', (tester) async {
    String? selected;
    await tester.pumpWidget(
      app(
        AppDropdown<String>(
          label: 'Vehicle',
          value: null,
          items: const ['Van', 'Truck'],
          hintText: 'Choose vehicle',
          itemLabelBuilder: (item) => item,
          onChanged: (value) => selected = value,
        ),
      ),
    );
    expect(find.text('VEHICLE'), findsOneWidget);
    expect(find.text('Choose vehicle'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Truck').last);
    expect(selected, 'Truck');
  });

  testWidgets('AppComboBox covers empty, selected, clear, and search states', (
    tester,
  ) async {
    String? changed;
    const items = ['Alpha', 'Beta'];
    final combo = AppComboBox<String>(
      label: 'Party',
      value: null,
      items: items,
      itemLabelBuilder: (item) => item,
      itemSubtitleBuilder: (item) => 'Subtitle $item',
      filterFn: (item, query) =>
          item.toLowerCase().contains(query.toLowerCase()),
      onChanged: (value) => changed = value,
      onAddPressed: () => changed = 'added',
      addLabel: 'Add party',
    );
    await tester.pumpWidget(app(combo));
    expect(find.text('Tap to select...'), findsOneWidget);
    await tester.tap(find.text('Tap to select...'));
    await tester.pumpAndSettle();
    expect(find.text('Select Party'), findsOneWidget);
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(changed, 'Beta');

    await tester.pumpWidget(
      app(
        AppComboBox<String>(
          label: 'Party',
          value: 'Alpha',
          items: items,
          itemLabelBuilder: (item) => item,
          filterFn: (_, _) => true,
          onChanged: (value) => changed = value,
        ),
      ),
    );
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Subtitle Alpha'), findsNothing);
    await tester.tap(find.text('Clear'));
    expect(changed, isNull);
  });

  testWidgets('AppDateTimePicker formats values and opens picker', (
    tester,
  ) async {
    final date = DateTime(2026, 7, 18, 13, 45);
    await tester.pumpWidget(
      app(
        Column(
          children: [
            AppDateTimePicker(
              label: 'Date',
              value: date,
              mode: AppDateTimePickerMode.date,
              onChanged: (_) {},
            ),
            AppDateTimePicker(
              label: 'Time',
              value: date,
              mode: AppDateTimePickerMode.time,
              onChanged: (_) {},
            ),
            AppDateTimePicker(
              label: 'Date time',
              value: date,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    expect(find.text(Formatters.date(date)), findsOneWidget);
    expect(find.text(Formatters.time(date)), findsOneWidget);
    expect(find.text(Formatters.dateTime(date)), findsOneWidget);

    await tester.tap(find.text(Formatters.date(date)));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    await tester.tap(find.text('Done'));
  });

  testWidgets('ExtraRow exposes edit and delete actions', (tester) async {
    var edits = 0;
    var deletes = 0;
    await tester.pumpWidget(
      app(
        ExtraRow(
          name: 'Waiting',
          amount: '10.00',
          onEdit: () => edits++,
          onDelete: () => deletes++,
        ),
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.pencil));
    await tester.tap(find.byIcon(CupertinoIcons.trash));
    expect(edits, 1);
    expect(deletes, 1);
  });

  testWidgets('DemoSheet shows subtitle, child, close, and busy overlay', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      app(
        DemoSheet(
          title: 'Edit item',
          subtitle: 'Details',
          child: const Text('Form'),
          onClose: () => closed = true,
        ),
      ),
    );
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Form'), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    expect(closed, isTrue);

    await tester.pumpWidget(
      app(
        const DemoSheet(
          title: 'Saving',
          busy: true,
          loadingMessage: 'Saving now',
          child: Text('Form'),
        ),
      ),
    );
    expect(find.text('Saving now'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is IgnorePointer && widget.ignoring,
      ),
      findsOneWidget,
    );
  });

  testWidgets('PaginatedListView renders loading, empty, failure, and items', (
    tester,
  ) async {
    final loading = PaginationController<String>(
      callback: (_, _) async {
        return const Success(
          PaginatedResult<String>(
            items: [],
            pageNumber: 1,
            pageSize: 10,
            totalRecords: 0,
          ),
        );
      },
    );
    await tester.pumpWidget(
      app(
        SizedBox(
          height: 500,
          child: PaginatedListView<String>(
            controller: loading,
            itemBuilder: (_, item, _) => Text(item),
          ),
        ),
      ),
    );
    expect(find.byType(AppLoadingIndicator), findsOneWidget);

    await loading.loadInitial();
    await tester.pumpWidget(
      app(
        SizedBox(
          height: 500,
          child: PaginatedListView<String>(
            controller: loading,
            itemBuilder: (_, item, _) => Text(item),
          ),
        ),
      ),
    );
    expect(find.text('No items found'), findsOneWidget);

    final failure = PaginationController<String>(
      callback: (_, _) async {
        return const Failure(NetworkFailure('offline'));
      },
    );
    await tester.pumpWidget(
      app(
        SizedBox(
          height: 500,
          child: PaginatedListView<String>(
            controller: failure,
            itemBuilder: (_, item, _) => Text(item),
          ),
        ),
      ),
    );
    await failure.loadInitial();
    await tester.pumpWidget(
      app(
        SizedBox(
          height: 500,
          child: PaginatedListView<String>(
            controller: failure,
            itemBuilder: (_, item, _) => Text(item),
          ),
        ),
      ),
    );
    expect(find.text("Couldn't load items"), findsOneWidget);

    final items = PaginationController<String>(
      callback: (page, _) async {
        return Success(
          PaginatedResult<String>(
            items: page == 1 ? const ['one'] : const ['two'],
            pageNumber: page,
            pageSize: 1,
            totalRecords: 2,
          ),
        );
      },
    );
    await items.loadInitial();
    await tester.pumpWidget(
      app(
        SizedBox(
          height: 500,
          child: PaginatedListView<String>(
            controller: items,
            separator: const Divider(),
            itemBuilder: (_, item, _) => Text(item),
          ),
        ),
      ),
    );
    expect(find.text('one'), findsOneWidget);
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });
}
