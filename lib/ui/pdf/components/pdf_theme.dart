import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Shared color, contrast, and layout tokens for the PDF document builders.

PdfColor get navy => PdfColor.fromInt(AppColors.navy.toARGB32());
PdfColor get muted => PdfColor.fromInt(AppColors.muted.toARGB32());

final double pageContentWidth = PdfPageFormat.a4.width - 76;

/// Blends [color] toward white by [amount] (0..1) as an opaque color.
/// `pw.TableRow` decorations don't reliably honor alpha, so we blend the
/// RGB channels directly rather than relying on a transparent fill.
PdfColor tint(PdfColor color, [double amount = 0.2]) {
  double mix(double channel) => channel * amount + (1 - amount);
  return PdfColor(mix(color.red), mix(color.green), mix(color.blue));
}

double luminance(PdfColor c) =>
    0.2126 * c.red + 0.7152 * c.green + 0.0722 * c.blue;

/// Dark or light text — never the tint itself — chosen by [background]'s brightness.
PdfColor readableTextColor(PdfColor background) =>
    luminance(background) > 0.55 ? navy : PdfColors.white;

/// [accent] as text color on the white page, falling back to navy if too pale to read.
PdfColor accentOrFallback(PdfColor accent) =>
    luminance(accent) > 0.55 ? navy : accent;

final smallHeading = pw.TextStyle(
  fontSize: 8,
  color: muted,
  fontWeight: pw.FontWeight.bold,
);
final tableHeader = pw.TextStyle(
  fontSize: 8,
  color: navy,
  fontWeight: pw.FontWeight.bold,
);
final tableCell = pw.TextStyle(fontSize: 9, color: navy);
