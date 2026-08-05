import 'package:fleetgo/ui/pdf/components/pdf_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Hand-built table (not [pw.TableHelper.fromTextArray], which doesn't
/// support per-row decorations here) with a brand-colored header band; data
/// rows stay plain so the color reads as structure, not as another "value".
pw.Widget lineTable({
  required List<String> headers,
  required List<List<String>> rows,
  required List<double> columnFractions,
  required PdfColor accent,
}) {
  final headerTint = tint(accent);
  return pw.Table(
    columnWidths: {
      for (var i = 0; i < columnFractions.length; i++)
        i: pw.FlexColumnWidth(columnFractions[i]),
    },
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: headerTint,
          border: pw.Border(bottom: pw.BorderSide(color: accent, width: 1.2)),
        ),
        children: [
          for (var i = 0; i < headers.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: pw.Text(
                headers[i],
                style: tableHeader.copyWith(color: readableTextColor(headerTint)),
                textAlign: i == 0 ? pw.TextAlign.left : pw.TextAlign.right,
              ),
            ),
        ],
      ),
      for (final row in rows)
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
            ),
          ),
          children: [
            for (var i = 0; i < row.length; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.all(7),
                child: pw.Text(
                  row[i],
                  style: i == 0
                      ? tableCell.copyWith(fontWeight: pw.FontWeight.bold)
                      : tableCell,
                  textAlign: i == 0 ? pw.TextAlign.left : pw.TextAlign.right,
                ),
              ),
          ],
        ),
    ],
  );
}
