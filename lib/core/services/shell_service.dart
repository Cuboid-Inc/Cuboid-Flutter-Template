import 'package:stacked/stacked.dart';

class ShellService with ListenableServiceMixin {
  final _index = ReactiveValue<int>(0);

  int get index => _index.value;

  ShellService() {
    listenToReactiveValues([_index]);
  }

  void setIndex(int value) {
    _index.value = value;
  }
}
