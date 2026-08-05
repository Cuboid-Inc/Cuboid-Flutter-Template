import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/features/shell/shell_service.dart';
import 'package:stacked/stacked.dart';

class ShellViewModel extends ReactiveViewModel {
  final _shellService = locator<ShellService>();

  int get index => _shellService.index;

  void setIndex(int value) {
    _shellService.setIndex(value);
  }

  @override
  List<ListenableServiceMixin> get listenableServices => [_shellService];
}
