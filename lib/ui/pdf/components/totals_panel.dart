import 'package:cuboid_flutter_template/ui/pdf/components/pdf_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Totals panel, right-aligned under the line table. Plain (no fill) except
/// for an accent-colored rule and Total row, so it reads as a summary rather
/// than another highlighted value block.
pw.Widget totalsPanel({
  required List<(String, String)> rows,
  required PdfColor accent,
  required double width,
}) => pw.Align(
  alignment: pw.Alignment.centerRight,
  child: pw.Container(
    width: width,
    padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 10),
    child: pw.Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i == rows.length - 1 && rows.length > 1)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Divider(color: accent, height: 1, thickness: 1),
            ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  rows[i].$1,
                  textAlign: pw.TextAlign.end,
                  style: pw.TextStyle(
                    fontWeight: i == rows.length - 1
                        ? pw.FontWeight.bold
                        : null,
                    fontSize: i == rows.length - 1 ? 12 : 10,
                    color: i == rows.length - 1 ? accent : navy,
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text(
                  rows[i].$2,
                  textAlign: pw.TextAlign.end,
                  style: pw.TextStyle(
                    fontWeight: i == rows.length - 1
                        ? pw.FontWeight.bold
                        : null,
                    fontSize: i == rows.length - 1 ? 12 : 10,
                    color: i == rows.length - 1 ? accent : navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  ),
);
