import 'package:stacked/stacked.dart';

class ShellService with ListenableServiceMixin {
  ShellService() {
    listenToReactiveValues([_index]);
  }

  final ReactiveValue<int> _index = ReactiveValue<int>(0);

  int get index => _index.value;

  void setIndex(int value) => _index.value = value;
}
