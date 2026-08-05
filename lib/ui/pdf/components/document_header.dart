import 'package:cuboid_flutter_template/ui/pdf/components/pdf_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Recipient-forward document header: recipient block on the left, a large
/// plain-ink document title with issue stats on the right, one hairline rule
/// below the whole block.
pw.Widget documentHeader({
  required String recipientLabel,
  required String recipientName,
  required String title,
  required PdfColor accent,
  List<String> recipientDetailLines = const [],
  String? titleSubtitle,
  required List<(String, String)> stats,
}) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(recipientLabel, style: smallHeading),
            pw.SizedBox(height: 4),
            pw.Text(
              recipientName,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            for (final line in recipientDetailLines) ...[
              pw.SizedBox(height: 2),
              pw.Text(line, style: pw.TextStyle(fontSize: 9, color: muted)),
            ],
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: accentOrFallback(accent),
              ),
            ),
            if (titleSubtitle != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                titleSubtitle,
                style: pw.TextStyle(fontSize: 9, color: muted),
              ),
            ],
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                for (var i = 0; i < stats.length; i++)
                  pw.Container(
                    margin: pw.EdgeInsets.only(left: i == 0 ? 0 : 14),
                    padding: pw.EdgeInsets.only(left: i == 0 ? 0 : 10),
                    decoration: i == 0
                        ? null
                        : const pw.BoxDecoration(
                            border: pw.Border(
                              left: pw.BorderSide(color: PdfColors.grey300),
                            ),
                          ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(stats[i].$1, style: smallHeading),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          stats[i].$2,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    ),
    pw.SizedBox(height: 10),
    pw.Divider(color: PdfColors.grey300, thickness: 1),
    pw.SizedBox(height: 8),
  ],
);
