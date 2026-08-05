import 'package:stacked/stacked.dart';
import 'package:fleetgo/core/enums/enums.dart';

class ShellService with ListenableServiceMixin {
  final _index = ReactiveValue<int>(0);
  final _moneySegment = ReactiveValue<MoneySegment>(MoneySegment.invoices);
  final _workFilter = ReactiveValue<WorkStatus?>(null);

  int get index => _index.value;
  MoneySegment get moneySegment => _moneySegment.value;
  WorkStatus? get workFilter => _workFilter.value;

  ShellService() {
    listenToReactiveValues([_index, _moneySegment, _workFilter]);
  }

  void setIndex(int value) {
    _index.value = value;
  }

  void setMoneySegment(MoneySegment value) {
    _moneySegment.value = value;
  }

  void setWorkFilter(WorkStatus? value) {
    _workFilter.value = value;
  }
}
