import 'package:cuboid_flutter_template/features/shell/shell_service.dart';
import 'package:cuboid_flutter_template/features/shell/shell_view.dart';
import 'package:cuboid_flutter_template/features/startup/startup_view.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/invite_staff_form/invite_staff_form_sheet.dart';
import 'package:cuboid_flutter_template/ui/dialogs/confirm/confirm_dialog.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: StartupView, initial: true),
    MaterialRoute(page: ShellView),
    // @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: SnackbarService),
    LazySingleton(classType: ShellService),
    // @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: InviteStaffFormSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: ConfirmDialog),
    // @stacked-dialog
  ],
)
class App {}
