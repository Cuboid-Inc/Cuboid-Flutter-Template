import 'dart:io';

import 'package:cuboid_flutter_template/core/pdf/letterhead_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FilePickerStub extends FilePickerPlatform {
  _FilePickerStub(this.result);

  final FilePickerResult? result;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) async => result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LetterheadUpload marks uploads below A4 print resolution', () {
    expect(const LetterheadUpload('low', 1239, 1753).isLowRes, isTrue);
    expect(const LetterheadUpload('low', 1239, 1754).isLowRes, isFalse);
    expect(const LetterheadUpload('good', 1240, 1754).isLowRes, isFalse);
  });

  test('pickLetterhead returns null when the picker is cancelled', () async {
    final original = FilePickerPlatform.instance;
    FilePickerPlatform.instance = _FilePickerStub(null);
    addTearDown(() => FilePickerPlatform.instance = original);

    expect(await pickLetterhead(), isNull);
  });

  test(
    'pickLetterhead stores a selected image and reads its dimensions',
    () async {
      final source = File(
        '${Directory.systemTemp.path}/fleetgo_letterhead_pick_test.png',
      );
      final bytes = UriData.parse(
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ).contentAsBytes();
      await source.writeAsBytes(bytes);

      final originalPicker = FilePickerPlatform.instance;
      const pathProviderChannel = MethodChannel(
        'plugins.flutter.io/path_provider',
      );
      FilePickerPlatform.instance = _FilePickerStub(
        FilePickerResult([
          PlatformFile(
            name: 'header.png',
            path: source.path,
            size: bytes.length,
          ),
        ]),
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            pathProviderChannel,
            (_) async => Directory.systemTemp.path,
          );
      addTearDown(() async {
        FilePickerPlatform.instance = originalPicker;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProviderChannel, null);
        if (await source.exists()) await source.delete();
      });

      final upload = await pickLetterhead();

      expect(upload, isNotNull);
      expect(upload!.width, 1);
      expect(upload.height, 1);
      expect(await File(upload.path).exists(), isTrue);
      await deleteLetterhead(upload.path);
    },
  );

  test(
    'deleteLetterhead deletes an existing file and ignores a missing file',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/fleetgo_letterhead_store_test.png',
      );
      await file.writeAsBytes([1, 2, 3]);
      await deleteLetterhead(file.path);
      expect(await file.exists(), isFalse);

      await deleteLetterhead(file.path);
    },
  );
}
