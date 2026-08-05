import 'package:stacked/stacked.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/features/shell/shell_service.dart';

class ShellViewModel extends ReactiveViewModel {
  final _shellService = locator<ShellService>();

  int get index => _shellService.index;

  void setIndex(int value) {
    _shellService.setIndex(value);
  }

  @override
  List<ListenableServiceMixin> get listenableServices => [_shellService];
}
