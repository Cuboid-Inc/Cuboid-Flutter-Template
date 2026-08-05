import 'dart:typed_data';

import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/business_profile.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/core/models/report_models.dart';
import 'package:fleetgo/core/models/settlement.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/core/money.dart';
import 'package:fleetgo/ui/pdf/components/document_footer.dart';
import 'package:fleetgo/ui/pdf/components/document_header.dart';
import 'package:fleetgo/ui/pdf/components/line_table.dart';
import 'package:fleetgo/ui/pdf/components/payment_notes.dart';
import 'package:fleetgo/ui/pdf/components/pdf_page_theme.dart';
import 'package:fleetgo/ui/pdf/components/pdf_theme.dart';
import 'package:fleetgo/ui/pdf/components/totals_panel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// True-scale preview of the letterhead with placeholder content, so the
/// client can judge sharpness/positioning before saving it to their profile.
Future<Uint8List> buildLetterheadPreviewPdf(BusinessProfile profile) async {
  final document = pw.Document();
  document.addPage(
    pw.Page(
      pageTheme: await pageTheme(profile),
      build: (_) => pw.DecoratedBox(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.grey400,
            style: pw.BorderStyle.dashed,
          ),
        ),
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Sample content area',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'This box marks where invoice/trip-sheet text will print.',
              ),
              pw.SizedBox(height: 6),
              pw.Text('Total   AED 1,234.00'),
            ],
          ),
        ),
      ),
    ),
  );
  return document.save();
}

Future<Uint8List> buildInvoicePdf(
  Invoice invoice,
  BusinessProfile profile,
) async {
  final document = pw.Document();
  final accent = PdfColor.fromInt(profile.brandColor);
  final hasLetterhead =
      profile.useCustomLetterhead && profile.letterheadPath != null;
  final termsLine = invoice.dueDate == null
      ? invoice.paymentTerms
      : '${invoice.paymentTerms} · Due ${Formatters.date(invoice.dueDate!)}';
  document.addPage(
    pw.MultiPage(
      pageTheme: await pageTheme(profile),
      header: hasLetterhead
          ? null
          : (_) => documentHeader(
              recipientLabel: 'BILL TO',
              recipientName: invoice.buyerName,
              recipientDetailLines: [
                if (invoice.buyerTrn != null) 'TRN ${invoice.buyerTrn}',
                termsLine,
              ],
              title: 'Tax Invoice',
              accent: accent,
              stats: [
                ('ISSUE DATE', Formatters.date(invoice.issueDate)),
                ('INVOICE NO.', invoice.number),
              ],
            ),
      footer: hasLetterhead
          ? null
          : (context) => documentFooter(profile, context),
      build: (_) => [
        lineTable(
          headers: const ['DESCRIPTION', 'QTY', 'UNIT PRICE', 'VAT', 'GROSS'],
          columnFractions: const [0.38, 0.10, 0.18, 0.12, 0.22],
          rows: [
            for (final line in invoice.lines)
              [
                line.name,
                '${line.quantity}',
                Formatters.money(line.unitPrice),
                '${line.vatRate}%',
                Formatters.money(line.gross),
              ],
          ],
          accent: accent,
        ),
        totalsPanel(
          rows: [
            ('Net', Formatters.money(invoice.net)),
            ('VAT', Formatters.money(invoice.vat)),
            ('Total', Formatters.money(invoice.gross)),
          ],
          accent: accent,
          width: pageContentWidth * 0.44,
        ),
        paymentNotes(profile),
        pw.SizedBox(height: 24),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            signatureLine('Owner / Manager signature'),
            signatureLine('Party signature'),
          ],
        ),
        pw.SizedBox(height: 24),
      ],
    ),
  );
  return document.save();
}

Future<Uint8List> buildTripSheetPdf(
  WorkOrder workOrder,
  BusinessProfile profile, [
  DateTime? generatedAt,
]) async {
  final document = pw.Document();
  final accent = PdfColor.fromInt(profile.brandColor);
  final hasLetterhead =
      profile.useCustomLetterhead && profile.letterheadPath != null;
  document.addPage(
    pw.MultiPage(
      pageTheme: await pageTheme(profile),
      header: hasLetterhead
          ? null
          : (_) => documentHeader(
              recipientLabel: 'ROUTE',
              recipientName: workOrder.route,
              recipientDetailLines: ['Status ${workOrder.status.name}'],
              title: 'Trip Sheet',
              accent: accent,
              stats: [
                ('DATE', Formatters.date(workOrder.date)),
                ('WORK ORDER NO.', workOrder.number),
              ],
            ),
      footer: hasLetterhead
          ? null
          : (context) => documentFooter(profile, context),
      build: (_) => [
        lineTable(
          headers: const ['DESCRIPTION', 'QTY', 'UNIT PRICE', 'VAT', 'GROSS'],
          columnFractions: const [0.38, 0.10, 0.18, 0.12, 0.22],
          rows: [
            for (final line in workOrder.chargeLines)
              [
                line.name,
                '${line.quantity}',
                Formatters.money(line.unitPrice),
                '${line.vatRate}%',
                Formatters.money(line.gross),
              ],
          ],
          accent: accent,
        ),
        totalsPanel(
          rows: [
            ('Net', Formatters.money(workOrder.net)),
            ('VAT', Formatters.money(workOrder.vat)),
            ('Total', Formatters.money(workOrder.gross)),
          ],
          accent: accent,
          width: pageContentWidth * 0.44,
        ),
        paymentNotes(profile),
        pw.Spacer(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            signatureLine('Manager / Driver signature'),
            signatureLine('Party signature'),
          ],
        ),
        pw.SizedBox(height: 24),
      ],
    ),
  );
  return document.save();
}

Future<Uint8List> buildStatementPdf(
  Party party,
  List<StatementRow> rows,
  Period period,
  BusinessProfile profile,
  String Function(String workOrderId) workOrderNumber,
) async {
  final document = pw.Document();
  final accent = PdfColor.fromInt(profile.brandColor);
  final total = rows.fold<num>(0, (sum, r) => roundMoney(sum + r.amount));
  final hasLetterhead =
      profile.useCustomLetterhead && profile.letterheadPath != null;
  document.addPage(
    pw.MultiPage(
      pageTheme: await pageTheme(profile),
      header: hasLetterhead
          ? null
          : (_) => documentHeader(
              recipientLabel: 'STATEMENT FOR',
              recipientName: party.name,
              recipientDetailLines: [
                if (party.trn != null) 'TRN ${party.trn}',
                party.paymentTerms.label,
              ],
              title: 'Monthly Statement',
              accent: accent,
              stats: [('PERIOD', Formatters.monthYear(period.start))],
            ),
      footer: hasLetterhead
          ? null
          : (context) => documentFooter(profile, context),
      build: (_) => [
        lineTable(
          headers: const ['DATE', 'WORK ORDER', 'DESCRIPTION', 'AMOUNT'],
          columnFractions: const [0.16, 0.22, 0.38, 0.24],
          rows: [
            for (final row in rows)
              [
                Formatters.date(row.date),
                workOrderNumber(row.workOrderId),
                row.description,
                Formatters.money(row.amount),
              ],
          ],
          accent: accent,
        ),
        totalsPanel(
          rows: [('Total', Formatters.money(total))],
          accent: accent,
          width: pageContentWidth * 0.44,
        ),
        paymentNotes(profile),
        paymentNotes(profile),
        pw.Spacer(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            signatureLine('Owner / Manager signature'),
            signatureLine('Party signature'),
          ],
        ),
        pw.SizedBox(height: 24),
      ],
    ),
  );
  return document.save();
}

Future<Uint8List> buildSettlementPdf(
  Party supplier,
  List<SettlementLine> lines,
  SupplierSettlement settlement,
  BusinessProfile profile,
  String Function(String workOrderId) workOrderNumber,
  String Function(String vehicleId) vehicleLabel,
) async {
  final document = pw.Document();
  final accent = PdfColor.fromInt(profile.brandColor);
  final hasLetterhead =
      profile.useCustomLetterhead && profile.letterheadPath != null;
  document.addPage(
    pw.MultiPage(
      pageTheme: await pageTheme(profile),
      header: hasLetterhead
          ? null
          : (_) => documentHeader(
              recipientLabel: 'SETTLEMENT TO',
              recipientName: supplier.name,
              recipientDetailLines: [
                if (supplier.trn != null) 'TRN ${supplier.trn}',
                supplier.paymentTerms.label,
              ],
              title: 'Supplier Settlement',
              titleSubtitle: settlement.number,
              accent: accent,
              stats: [
                ('PERIOD START', Formatters.date(settlement.periodStart)),
                ('PERIOD END', Formatters.date(settlement.periodEnd)),
              ],
            ),
      footer: hasLetterhead
          ? null
          : (context) => documentFooter(profile, context),
      build: (_) => [
        lineTable(
          headers: const ['DATE', 'WORK ORDER', 'ROUTE', 'VEHICLE', 'AMOUNT'],
          columnFractions: const [0.14, 0.18, 0.28, 0.18, 0.22],
          rows: [
            for (final line in lines)
              [
                Formatters.date(line.date),
                workOrderNumber(line.workOrderId),
                line.route ?? '—',
                line.vehicleId == null ? '—' : vehicleLabel(line.vehicleId!),
                Formatters.money(line.amount),
              ],
          ],
          accent: accent,
        ),
        totalsPanel(
          rows: [('Total', Formatters.money(settlement.total))],
          accent: accent,
          width: pageContentWidth * 0.44,
        ),
        paymentNotes(profile),
        paymentNotes(profile),
        pw.Spacer(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            signatureLine('Owner / Manager signature'),
            signatureLine('Supplier signature'),
          ],
        ),
        pw.SizedBox(height: 24),
      ],
    ),
  );
  return document.save();
}
