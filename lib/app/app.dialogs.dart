// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedDialogGenerator
// **************************************************************************

import 'package:stacked_services/stacked_services.dart';

import 'app.locator.dart';
import '../ui/dialogs/add_edit_extra/add_edit_extra_dialog.dart';
import '../ui/dialogs/confirm/confirm_dialog.dart';

enum DialogType { confirm, addEditExtra }

void setupDialogUi() {
  final dialogService = locator<DialogService>();

  final Map<DialogType, DialogBuilder> builders = {
    DialogType.confirm: (context, request, completer) =>
        ConfirmDialog(request: request, completer: completer),
    DialogType.addEditExtra: (context, request, completer) =>
        AddEditExtraDialog(request: request, completer: completer),
  };

  dialogService.registerCustomDialogBuilders(builders);
}
