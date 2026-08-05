import 'dart:io';

import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/business_profile.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/core/models/report_models.dart';
import 'package:fleetgo/core/models/settlement.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/ui/pdf/fleet_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

const _onePixelPng = <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x04,
  0x00,
  0x00,
  0x00,
  0xb5,
  0x1c,
  0x0c,
  0x02,
  0x00,
  0x00,
  0x00,
  0x0b,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0xda,
  0x63,
  0x64,
  0xf8,
  0x0f,
  0x00,
  0x01,
  0x05,
  0x01,
  0x01,
  0x27,
  0x18,
  0xe3,
  0x66,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File letterhead;

  setUpAll(() async {
    letterhead = File(
      '${Directory.systemTemp.path}/fleetgo_test_letterhead.png',
    );
    await letterhead.writeAsBytes(_onePixelPng);
  });

  tearDownAll(() async {
    if (await letterhead.exists()) await letterhead.delete();
  });

  test('builds a letterhead preview with and without a background', () async {
    expect(await buildLetterheadPreviewPdf(_profile()), isNotEmpty);
    expect(
      await buildLetterheadPreviewPdf(
        _profile(letterheadPath: letterhead.path),
      ),
      isNotEmpty,
    );
  });

  test('builds invoices for optional and populated line data', () async {
    final empty = Invoice(
      id: 'invoice-empty',
      number: 'INV-EMPTY',
      buyerId: 'customer-1',
      buyerName: 'Customer',
      issueDate: DateTime(2026, 7, 18),
    );
    expect(await buildInvoicePdf(empty, _profile()), isNotEmpty);
    expect(
      await buildInvoicePdf(
        empty,
        _profile(footer: null, paymentInstructions: 'Pay by cheque'),
      ),
      isNotEmpty,
    );
    expect(
      await buildInvoicePdf(
        empty,
        _profile(footer: null, paymentInstructions: null),
      ),
      isNotEmpty,
    );

    final invoice = Invoice(
      id: 'invoice-1',
      number: 'INV-2026-001',
      buyerId: 'customer-1',
      buyerName: 'Gulf Star Contracting',
      buyerAddress: 'Street 1, Dubai',
      buyerTrn: '100000000000003',
      paymentTerms: 'Net 30',
      issueDate: DateTime(2026, 7, 18),
      dueDate: DateTime(2026, 8, 17),
      lines: [
        InvoiceLine(name: 'Trip', quantity: 2, unitPrice: 500),
        InvoiceLine(name: 'Toll', unitPrice: 25, vatRate: 0),
      ],
      status: InvoiceStatus.issued,
    );
    expect(await buildInvoicePdf(invoice, _profile()), isNotEmpty);
    expect(
      await buildInvoicePdf(invoice, _profile(letterheadPath: letterhead.path)),
      isNotEmpty,
    );
  });

  test('builds trip sheets for empty and populated allocations', () async {
    final empty = WorkOrder(
      id: 'work-empty',
      number: 'WO-EMPTY',
      customerId: 'customer-1',
      date: DateTime(2026, 7, 18),
      pickup: 'Dubai',
      destination: 'Abu Dhabi',
      status: WorkStatus.canceled,
    );
    expect(await buildTripSheetPdf(empty, _profile()), isNotEmpty);

    final workOrder = WorkOrder(
      id: 'work-1',
      number: 'WO-2026-001',
      customerId: 'customer-1',
      agreementId: 'agreement-1',
      date: DateTime(2026, 7, 18),
      pickup: 'Dubai',
      destination: 'Abu Dhabi',
      allocations: const [
        VehicleAllocation(vehicleId: 'TRK-01', driverId: 'driver-1'),
        VehicleAllocation(vehicleId: 'TRK-02', source: VehicleSource.supplier),
      ],
      chargeLines: const [
        ChargeLine(name: 'Trip', quantity: 2, unitPrice: 500),
        ChargeLine(name: 'Toll', unitPrice: 25, vatRate: 0),
      ],
      status: WorkStatus.completed,
    );
    expect(
      await buildTripSheetPdf(workOrder, _profile(), DateTime(2026, 7, 18)),
      isNotEmpty,
    );
    expect(
      await buildTripSheetPdf(
        workOrder,
        _profile(letterheadPath: letterhead.path),
      ),
      isNotEmpty,
    );
  });

  test('builds statements with empty and populated rows', () async {
    const party = Party(
      id: 'customer-1',
      name: 'Gulf Star Contracting',
      type: PartyType.customer,
      trn: '100000000000003',
      phone: '+971500000000',
      paymentTerms: PaymentTerms.net30,
    );
    expect(
      await buildStatementPdf(
        party,
        const [],
        Period.month(2026, 7),
        _profile(),
        _identity,
      ),
      isNotEmpty,
    );

    final rows = [
      StatementRow(
        partyId: 'customer-1',
        date: DateTime(2026, 7, 1),
        workOrderId: 'work-1',
        description: 'Trip',
        amount: 1000,
      ),
      StatementRow(
        partyId: 'customer-1',
        date: DateTime(2026, 7, 2),
        workOrderId: 'other-2',
        description: 'Toll',
        amount: 25,
      ),
    ];
    expect(
      await buildStatementPdf(
        party,
        rows,
        Period.month(2026, 7),
        _profile(),
        _identity,
      ),
      isNotEmpty,
    );
    expect(
      await buildStatementPdf(
        party,
        rows,
        Period.month(2026, 7),
        _profile(letterheadPath: letterhead.path),
        _identity,
      ),
      isNotEmpty,
    );
  });

  test('builds settlements with nullable and populated line fields', () async {
    const supplier = Party(
      id: 'supplier-1',
      name: 'Desert Line Vehicles',
      type: PartyType.supplier,
      phone: '+971511111111',
      paymentTerms: PaymentTerms.net15,
    );
    final settlement = SupplierSettlement(
      id: 'settlement-1',
      number: 'SET-2026-001',
      supplierId: supplier.id,
      periodStart: DateTime(2026, 7, 1),
      periodEnd: DateTime(2026, 7, 31),
      lines: [
        SettlementLine(
          workOrderId: 'work-1',
          date: DateTime(2026, 7, 1),
          amount: 300,
          route: 'Dubai to Abu Dhabi',
          vehicleId: 'TRK-01',
        ),
      ],
      status: SettlementStatus.issued,
    );
    expect(
      await buildSettlementPdf(
        supplier,
        const [],
        settlement,
        _profile(),
        _identity,
        _identity,
      ),
      isNotEmpty,
    );
    expect(
      await buildSettlementPdf(
        supplier,
        settlement.lines,
        settlement,
        _profile(),
        _identity,
        _identity,
      ),
      isNotEmpty,
    );
    expect(
      await buildSettlementPdf(
        supplier,
        [
          SettlementLine(
            workOrderId: 'work-2',
            date: DateTime(2026, 7, 2),
            amount: 200,
          ),
        ],
        settlement,
        _profile(letterheadPath: letterhead.path),
        _identity,
        _identity,
      ),
      isNotEmpty,
    );
  });
}

String _identity(String id) => id;

BusinessProfile _profile({
  String? letterheadPath,
  String? footer = 'Payment by bank transfer',
  String? paymentInstructions,
}) => BusinessProfile(
  legalName: 'FleetGo LLC',
  trn: '100000000000003',
  address: 'Street 1',
  city: 'Dubai',
  phone: '+971500000000',
  footer: footer,
  paymentInstructions: paymentInstructions,
  useCustomLetterhead: letterheadPath != null,
  letterheadPath: letterheadPath,
  letterheadMarginTopMm: 10,
  letterheadMarginBottomMm: 10,
  letterheadMarginLeftMm: 10,
  letterheadMarginRightMm: 10,
);
