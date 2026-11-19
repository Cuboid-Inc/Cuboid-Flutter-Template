/// Full-screen image cropping widget, pushed directly via
/// `NavigationService.navigateToView` (see `media_utils.dart`) rather than a
/// named route -- it is a destination, not a feature with its own view
/// model.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:cuboid_flutter_template/core/theme/app_colors.dart';
import 'package:cuboid_flutter_template/shared/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/shared/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';

class AppImageCropper extends StatefulWidget {
  const AppImageCropper({
    super.key,
    required this.image,
    required this.onCropped,
    this.circleCrop = false,
    this.saveCroppedFile = false,
  });

  final File image;
  final bool circleCrop;
  final bool saveCroppedFile;

  /// If [saveCroppedFile] is true, called with both the cropped file and its
  /// bytes; otherwise called with only the cropped bytes (file is `null`).
  final void Function(File? file, Uint8List? bytes) onCropped;

  @override
  State<AppImageCropper> createState() => _AppImageCropperState();
}

class _AppImageCropperState extends State<AppImageCropper> {
  static const _croppedFileExtension = '.jpg';

  final _cropController = CropController();
  late final Uint8List _image;
  bool _isCropping = false;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _image = widget.image.readAsBytesSync();
  }

  void _onCropped(CropResult result) {
    switch (result) {
      case CropSuccess(:final croppedImage):
        if (widget.saveCroppedFile) {
          final path =
              '${Directory.systemTemp.path}/'
              '${DateTime.now().microsecondsSinceEpoch}$_croppedFileExtension';
          final file = File(path)
            ..createSync(recursive: true)
            ..writeAsBytesSync(croppedImage);
          widget.onCropped(file, croppedImage);
        } else {
          widget.onCropped(null, croppedImage);
        }
      case CropFailure():
        widget.onCropped(null, null);
    }
  }

  void _handleCrop() {
    if (_isCropping) {
      return;
    }
    if (widget.circleCrop) {
      _cropController.cropCircle();
    } else {
      _cropController.crop();
    }
  }

  void _handlePreview() => setState(() => _isPreview = !_isPreview);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarIOS(
        title: _isCropping ? 'Please wait' : 'Crop image',
        actions: [
          if (_isCropping)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                height: 18,
                width: 18,
                child: AppLoadingIndicator(spinerColor: AppColors.primary),
              ),
            )
          else
            IconButton(
              onPressed: _handleCrop,
              icon: const Icon(Icons.check, size: 26),
            ),
        ],
      ),
      body: Crop(
        controller: _cropController,
        image: _image,
        onCropped: _onCropped,
        onStatusChanged: (status) {
          setState(() => _isCropping = status == CropStatus.cropping);
        },
        initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
          aspectRatio: 0.8,
        ),
        maskColor: _isPreview ? AppColors.white : null,
        baseColor: AppColors.bg,
        withCircleUi: widget.circleCrop,
        filterQuality: FilterQuality.high,
        clipBehavior: Clip.none,
        cornerDotBuilder: (size, edgeAlignment) => const DotControl(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handlePreview,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        icon: Icon(_isPreview ? Icons.undo : Icons.remove_red_eye_outlined),
        label: Text(_isPreview ? 'Undo' : 'Preview'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
