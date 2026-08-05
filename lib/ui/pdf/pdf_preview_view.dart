import 'dart:typed_data';

import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_bar_ios.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_loading_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewView extends StatelessWidget {
  const PdfPreviewView(
    this.title,
    Future<Uint8List> Function() build, {
    super.key,
  }) : _build = build;

  const PdfPreviewView.named({
    super.key,
    required this.title,
    required Future<Uint8List> Function() build,
  }) : _build = build;

  final String title;
  final Future<Uint8List> Function() _build;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBarIOS(title: title),
    body: Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: PdfPreview(
        build: (_) => _build(),
        canDebug: false,
        loadingWidget: AppLoadingIndicator(),
        actions: [
          PdfShareAction(
            filename: title.replaceAll(' ', '_'),
            icon: Icon(CupertinoIcons.share),
          ),
          PdfPrintAction(
            dynamicLayout: false,
            usePrinterSettings: true,
            jobName: title.replaceAll(' ', '_'),
            icon: Icon(CupertinoIcons.printer),
          ),
        ],
        useActions: false,
        actionBarTheme: const PdfActionBarTheme(
          backgroundColor: AppColors.white,
          iconColor: AppColors.primary,
          elevation: 0,
          textStyle: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
