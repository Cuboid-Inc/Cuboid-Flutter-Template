/// Image picking + cropping helpers, built on `NavigationService` (to push
/// [AppImageCropper] without a `BuildContext`) and `MessageService` (to
/// report picker failures). Accessed as a singleton (`MediaUtils.instance`)
/// rather than through the locator, matching other stateless app-wide
/// helpers in `lib/core/`.
library;

import 'dart:io';

import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/services/message_service.dart';
import 'package:cuboid_flutter_template/core/services/navigation_service.dart';
import 'package:cuboid_flutter_template/shared/widgets/app_image_cropper.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class MediaUtils {
  MediaUtils._();
  static final _instance = MediaUtils._();
  static MediaUtils get instance => _instance;

  final _nav = locator<NavigationService>();
  final _message = locator<MessageService>();
  final _picker = ImagePicker();

  /// Opens the image picker to select a single image. Returns `null` if the
  /// user cancels or the platform picker fails (a failure is also reported
  /// through [MessageService]).
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final result = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );
      return result == null ? null : File(result.path);
    } on PlatformException catch (error) {
      _message.showError(
        message: error.message ?? 'Something went wrong. Please try again.',
      );
      return null;
    } catch (_) {
      _message.showError(message: 'Something went wrong. Please try again.');
      return null;
    }
  }

  /// Opens the image picker, then [AppImageCropper] on the result. Returns
  /// the cropped file, or `null` if the user cancelled picking or cropping.
  Future<File?> pickWithCropper({
    bool fromCamera = false,
    bool isCircle = false,
  }) async {
    final file = await pickImage(fromCamera: fromCamera);
    if (file == null) {
      return null;
    }
    return openCropper(file, isCircle: isCircle);
  }

  /// Opens [AppImageCropper] on an already-picked [image]. Returns the
  /// cropped file, or `null` if the user cancelled cropping.
  Future<File?> openCropper(File image, {bool isCircle = false}) async {
    File? croppedFile;
    await _nav.navigateToView(
      AppImageCropper(
        image: image,
        saveCroppedFile: true,
        circleCrop: isCircle,
        onCropped: (file, bytes) {
          croppedFile = file;
          _nav.back();
        },
      ),
    );
    return croppedFile;
  }
}
