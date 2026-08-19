import 'package:cuboid_flutter/cuboid_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterViewModel extends CuboidViewModel {
  int count = 0;
  var disposed = false;

  void increment() {
    count += 1;
    notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

class _CounterView extends CuboidView<_CounterViewModel> {
  const _CounterView({required this.viewModel, this.onReady});

  final _CounterViewModel viewModel;
  final void Function(_CounterViewModel)? onReady;

  @override
  _CounterViewModel viewModelBuilder(BuildContext context) => viewModel;

  @override
  void onViewModelReady(_CounterViewModel viewModel) =>
      onReady?.call(viewModel);

  @override
  Widget builder(BuildContext context, _CounterViewModel vm, Widget? child) {
    return Text('count: ${vm.count}', textDirection: TextDirection.ltr);
  }
}

void main() {
  testWidgets('builds using viewModelBuilder and calls onViewModelReady', (
    tester,
  ) async {
    final viewModel = _CounterViewModel();
    _CounterViewModel? readyViewModel;

    await tester.pumpWidget(
      _CounterView(viewModel: viewModel, onReady: (vm) => readyViewModel = vm),
    );

    expect(readyViewModel, same(viewModel));
    expect(find.text('count: 0'), findsOneWidget);
  });

  testWidgets('rebuilds when the view model notifies listeners', (
    tester,
  ) async {
    final viewModel = _CounterViewModel();
    await tester.pumpWidget(_CounterView(viewModel: viewModel));

    viewModel.increment();
    await tester.pump();

    expect(find.text('count: 1'), findsOneWidget);
  });

  testWidgets('disposes the view model when the view is removed', (
    tester,
  ) async {
    final viewModel = _CounterViewModel();
    await tester.pumpWidget(_CounterView(viewModel: viewModel));

    await tester.pumpWidget(const SizedBox.shrink());

    expect(viewModel.disposed, isTrue);
  });
}
