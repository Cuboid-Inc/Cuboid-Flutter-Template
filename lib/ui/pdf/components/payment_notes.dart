import 'package:fleetgo/core/models/business_profile.dart';
import 'package:fleetgo/ui/pdf/components/pdf_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Payment instructions / notes block, only rendering the sections the
/// profile actually has content for.
pw.Widget paymentNotes(BusinessProfile profile) {
  final hasPayment = profile.paymentInstructions != null;
  final hasNotes = profile.footer != null;
  if (!hasPayment && !hasNotes) return pw.SizedBox();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (hasPayment) ...[
          pw.Text('PAYMENT INSTRUCTIONS', style: smallHeading),
          pw.SizedBox(height: 3),
          pw.Text(
            profile.paymentInstructions!,
            style: pw.TextStyle(fontSize: 9, color: muted),
          ),
          pw.SizedBox(height: 8),
        ],
        if (hasNotes) ...[
          pw.Text('NOTES', style: smallHeading),
          pw.SizedBox(height: 3),
          pw.Text(
            profile.footer!,
            style: pw.TextStyle(fontSize: 9, color: muted),
          ),
          pw.SizedBox(height: 8),
        ],
        pw.Text(
          'Thank you for your business.',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ],
    ),
  );
}

pw.Widget signatureLine(String label) => pw.SizedBox(
  width: 210,
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Divider(color: PdfColors.grey400),
      pw.Text(label, style: pw.TextStyle(color: muted)),
    ],
  ),
);
