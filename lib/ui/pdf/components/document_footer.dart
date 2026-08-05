import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/ui/pdf/components/pdf_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Business identity footer strip: legal name + Arabic name (if present) +
/// phone/TRN/email/address lines, only for fields the profile actually has.
/// No hardcoded fallback text.
pw.Widget documentFooter(BusinessProfile profile, pw.Context context) {
  final trailingParts = <String>[
    if (profile.trn != null) 'TRN: ${profile.trn}',
    if (profile.phone != null) 'Phone: ${profile.phone!}',
    if (profile.email != null) 'Email: ${profile.email!}',
    if (profile.address != null ||
        profile.city != null ||
        profile.country.isNotEmpty)
      'Address: ${[profile.address, profile.city, profile.country].whereType<String>().join(', ')}',
  ];
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.start,
    children: [
      pw.Divider(color: PdfColors.grey300),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            profile.legalName,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          ),
          if (profile.arabicLegalName != null) ...[
            pw.SizedBox(width: 8),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                profile.arabicLegalName!,
                style: pw.TextStyle(fontSize: 8, color: muted),
              ),
            ),
          ],
        ],
      ),
      ...trailingParts.map(
        (e) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Text(e, style: pw.TextStyle(fontSize: 8, color: muted)),
          ],
        ),
      ),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: muted),
          ),
        ],
      ),
    ],
  );
}
