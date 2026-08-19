import 'package:cuboid_flutter/cuboid_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CuboidViewModel', () {
    test('isBusy starts false', () {
      final viewModel = CuboidViewModel();

      expect(viewModel.isBusy, isFalse);
    });

    test('setBusy notifies listeners only on change', () {
      final viewModel = CuboidViewModel();
      var notifications = 0;
      viewModel.addListener(() => notifications += 1);

      viewModel.setBusy(true);
      viewModel.setBusy(true);
      viewModel.setBusy(false);

      expect(notifications, 2);
      expect(viewModel.isBusy, isFalse);
    });

    test('runBusy sets isBusy for the duration of the action', () async {
      final viewModel = CuboidViewModel();
      final busyDuringAction = <bool>[];

      final result = await viewModel.runBusy(() async {
        busyDuringAction.add(viewModel.isBusy);
        return 'done';
      });

      expect(result, 'done');
      expect(busyDuringAction, [true]);
      expect(viewModel.isBusy, isFalse);
    });

    test('runBusy clears isBusy even when the action throws', () async {
      final viewModel = CuboidViewModel();

      await expectLater(
        viewModel.runBusy(() async => throw StateError('boom')),
        throwsA(isA<StateError>()),
      );

      expect(viewModel.isBusy, isFalse);
    });
  });
}
