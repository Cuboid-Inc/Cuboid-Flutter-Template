import 'dart:io';

import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

pw.ThemeData? _unicodeTheme;
Future<pw.ThemeData> _theme() async => _unicodeTheme ??= pw.ThemeData.withFont(
  base: await PdfGoogleFonts.notoSansRegular(),
  bold: await PdfGoogleFonts.notoSansBold(),
  fontFallback: [
    await PdfGoogleFonts.notoSansSymbolsRegular(),
    await PdfGoogleFonts.notoSansSymbols2Regular(),
  ],
);

/// A page theme carrying the Unicode-capable font (always) and, when a
/// letterhead is uploaded, its background image + safe-area margins instead
/// of the default margin.
Future<pw.PageTheme> pageTheme(BusinessProfile profile) async {
  final theme = await _theme();
  final path = profile.useCustomLetterhead ? profile.letterheadPath : null;
  if (path == null) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(38),
      theme: theme,
    );
  }
  final image = pw.MemoryImage(await File(path).readAsBytes());
  return pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    theme: theme,
    margin: pw.EdgeInsets.fromLTRB(
      profile.letterheadMarginLeftMm * PdfPageFormat.mm,
      profile.letterheadMarginTopMm * PdfPageFormat.mm,
      profile.letterheadMarginRightMm * PdfPageFormat.mm,
      profile.letterheadMarginBottomMm * PdfPageFormat.mm,
    ),
    buildBackground: (_) => pw.FullPage(
      ignoreMargins: true,
      child: pw.Image(image, fit: pw.BoxFit.cover),
    ),
  );
}
