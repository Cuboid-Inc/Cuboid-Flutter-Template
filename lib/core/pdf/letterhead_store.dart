import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LetterheadUpload {
  const LetterheadUpload(this.path, this.width, this.height);

  final String path;
  final int width;
  final int height;

  // A4 at 150dpi ~= 1240x1754 - below that, print quality visibly suffers.
  bool get isLowRes => width < 1240 && height < 1754;
}

Future<LetterheadUpload?> pickLetterhead() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
  );
  final picked = result?.files.single;
  if (picked?.path == null) return null;

  final bytes = await File(picked!.path!).readAsBytes();
  final pngBytes = picked.extension?.toLowerCase() == 'pdf'
      ? await (await Printing.raster(
          bytes,
          pages: const [0],
          dpi: 300,
        ).first).toPng()
      : bytes;

  final dir = await getApplicationDocumentsDirectory();
  // A unique filename per upload avoids Flutter's FileImage cache (keyed by
  // path, not content) showing stale/blank previews after a Replace.
  final file = File(
    '${dir.path}/letterhead_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(pngBytes);

  final image = pw.MemoryImage(pngBytes);
  return LetterheadUpload(file.path, image.width ?? 0, image.height ?? 0);
}

Future<void> deleteLetterhead(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}
