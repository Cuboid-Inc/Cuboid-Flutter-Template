import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/amount_row.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/detail_header.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/invoice_status_chip.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/locked_banner.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/money_list_row.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/money_segment_tile.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/settlement_status_chip.dart';
import 'package:cuboid_flutter_template/features/money/ui/widgets/summary_amount_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('status chips map every invoice and settlement status', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Column(
          children: [
            InvoiceStatusChip(InvoiceStatus.paid),
            InvoiceStatusChip(InvoiceStatus.partPaid),
            InvoiceStatusChip(InvoiceStatus.issued),
            InvoiceStatusChip(InvoiceStatus.voided),
            InvoiceStatusChip(InvoiceStatus.draft),
            SettlementStatusChip(SettlementStatus.paid),
            SettlementStatusChip(SettlementStatus.partPaid),
            SettlementStatusChip(SettlementStatus.issued),
            SettlementStatusChip(SettlementStatus.voided),
            SettlementStatusChip(SettlementStatus.draft),
          ],
        ),
      ),
    );
    expect(find.text('Paid'), findsNWidgets(2));
    expect(find.text('Part Paid'), findsNWidgets(2));
    expect(find.text('Issued'), findsNWidgets(2));
    expect(find.text('Void'), findsNWidgets(2));
    expect(find.text('Draft'), findsNWidgets(2));
  });

  testWidgets('SummaryAmountCard and AmountRow show money values', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Column(
          children: [
            SummaryAmountCard(label: 'Balance', amount: 'AED 10.00'),
            AmountRow('Net', 10),
            AmountRow('Total', 12, strong: true),
          ],
        ),
      ),
    );
    expect(find.text('Balance'), findsOneWidget);
    expect(find.text('AED 10.00'), findsNWidgets(2));
    expect(find.text(Formatters.money(10)), findsNWidgets(2));
    expect(find.text(Formatters.money(12)), findsOneWidget);
  });

  testWidgets('DetailHeader supports an optional trailing widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Column(
          children: [
            DetailHeader(title: 'Invoice', subtitle: 'INV-1'),
            DetailHeader(
              title: 'Settlement',
              subtitle: 'SET-1',
              trailing: Icon(Icons.check),
            ),
          ],
        ),
      ),
    );
    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text('SET-1'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('LockedBanner covers paid and void states', (tester) async {
    await tester.pumpWidget(
      app(
        const Column(
          children: [
            LockedBanner(paid: true, message: 'Paid and locked'),
            LockedBanner(paid: false, message: 'Voided and locked'),
          ],
        ),
      ),
    );
    expect(find.text('Paid and locked'), findsOneWidget);
    expect(find.text('Voided and locked'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.check_mark_circled), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.xmark_circle), findsOneWidget);
  });

  testWidgets('MoneySegmentTile handles selected and unselected taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      app(
        Row(
          children: [
            Expanded(
              child: MoneySegmentTile(
                segment: MoneySegment.invoices,
                count: 2,
                selected: true,
                onTap: () => taps++,
              ),
            ),
            Expanded(
              child: MoneySegmentTile(
                segment: MoneySegment.payments,
                count: 3,
                selected: false,
                onTap: () => taps++,
              ),
            ),
          ],
        ),
      ),
    );
    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('Payments'), findsOneWidget);
    await tester.tap(find.text('Payments'));
    expect(taps, 1);
  });

  testWidgets('MoneyListRow covers number, trailing, and note branches', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Column(
          children: [
            MoneyListRow(
              number: 'INV-1',
              title: 'Customer',
              subtitle: 'Issued',
              amount: 'AED 20.00',
              trailing: Icon(Icons.more_horiz),
              note: 'AED 5.00',
            ),
            MoneyListRow(
              title: 'Expense',
              subtitle: 'Fuel',
              amount: 'AED 4.00',
            ),
          ],
        ),
      ),
    );
    expect(find.text('INV-1'), findsOneWidget);
    expect(find.text('Balance AED 5.00'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
  });
}
