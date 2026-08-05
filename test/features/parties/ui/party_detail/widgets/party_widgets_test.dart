import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/features/parties/ui/party_detail/widgets/party_info_card.dart';
import 'package:fleetgo/features/parties/ui/party_detail/widgets/party_open_invoice_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('PartyInfoCard renders optional party fields', (tester) async {
    const party = Party(
      id: 'p1',
      name: 'Gulf Star',
      type: PartyType.customer,
      contactPerson: 'Sam',
      phone: '123',
      email: 'sam@example.com',
      address: 'Street 1',
      city: 'Dubai',
      trn: 'TRN-1',
      notes: 'Preferred customer',
    );
    await tester.pumpWidget(app(PartyInfoCard(party: party)));
    expect(find.text('PARTY INFORMATION'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('TRN-1'), findsOneWidget);
    expect(find.text('Preferred customer'), findsOneWidget);
    expect(find.text(party.paymentTerms.label), findsOneWidget);
  });

  testWidgets('PartyOpenInvoiceTile formats invoice and handles taps', (
    tester,
  ) async {
    var tapped = false;
    final date = DateTime(2026, 7, 18);
    final invoice = Invoice(
      id: 'i1',
      number: 'INV-1',
      buyerId: 'p1',
      buyerName: 'Gulf Star',
      issueDate: date,
    );
    await tester.pumpWidget(
      app(
        PartyOpenInvoiceTile(
          invoice: invoice,
          balance: 99.5,
          onTap: () => tapped = true,
        ),
      ),
    );
    expect(find.text('INV-1'), findsOneWidget);
    expect(find.text('Issued ${Formatters.date(date)}'), findsOneWidget);
    expect(find.text(Formatters.money(99.5)), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
    await tester.tap(find.text('INV-1'));
    expect(tapped, isTrue);
  });
}
