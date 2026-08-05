import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/features/money/ui/invoice_detail/widgets/invoice_date_card.dart';
import 'package:fleetgo/features/money/ui/invoice_detail/widgets/invoice_line_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('InvoiceDateCard renders null and formatted dates', (
    tester,
  ) async {
    final date = DateTime(2026, 7, 18);
    await tester.pumpWidget(
      app(
        Column(
          children: [
            const InvoiceDateCard(label: 'Due date'),
            InvoiceDateCard(label: 'Issue date', date: date),
          ],
        ),
      ),
    );
    expect(find.text('DUE DATE'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text(Formatters.date(date)), findsOneWidget);
  });

  testWidgets('InvoiceLineTile delegates invoice line formatting', (
    tester,
  ) async {
    const line = InvoiceLine(
      name: 'Transport',
      quantity: 2,
      unit: 'trip',
      unitPrice: 50,
      discount: 5,
      vatRate: 5,
    );
    await tester.pumpWidget(app(const InvoiceLineTile(line: line)));
    expect(find.text('Transport'), findsOneWidget);
    expect(
      find.text('2 trip × 50.00 · Disc. 5.00 · VAT 5% · Net 95.00'),
      findsOneWidget,
    );
    expect(find.text(Formatters.rawMoney(line.gross)), findsOneWidget);
  });
}
