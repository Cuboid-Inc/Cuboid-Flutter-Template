import 'package:flutter/foundation.dart';

/// Base class for Cuboid view models.
///
/// Owns screen state and notifies [CuboidView] to rebuild via
/// [ChangeNotifier]. Provides busy-state tracking for asynchronous
/// orchestration.
class CuboidViewModel extends ChangeNotifier {
  bool _busy = false;

  bool get isBusy => _busy;

  void setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }

  /// Runs [action], setting [isBusy] for its duration. Always clears the
  /// busy flag, even when [action] throws.
  Future<T> runBusy<T>(Future<T> Function() action) async {
    setBusy(true);
    try {
      return await action();
    } finally {
      setBusy(false);
    }
  }
}
