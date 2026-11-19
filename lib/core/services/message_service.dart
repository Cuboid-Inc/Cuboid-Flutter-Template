/// Centralized, no-`BuildContext` message/snackbar service.
///
/// Mirrors `NavigationService`'s pattern (see
/// `lib/core/services/navigation_service.dart`): a static global
/// [GlobalKey] lets view models show messages without holding a
/// [BuildContext]. [scaffoldMessengerKey] must be attached to the root
/// [MaterialApp.scaffoldMessengerKey] (see `lib/app/app_root.dart`) for this
/// to work -- `cuboid create app` wires this up by default, and `cuboid
/// upgrade` adds it to older projects.
library;

import 'package:cuboid_flutter_template/app/app.snackbars.dart';
import 'package:flutter/material.dart';

class MessageService {
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  ScaffoldMessengerState get _messenger {
    final state = scaffoldMessengerKey.currentState;
    if (state == null) {
      throw StateError(
        'MessageService used before a ScaffoldMessenger exists.',
      );
    }
    return state;
  }

  /// Shows an error message.
  void showError({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 5),
  }) {
    _show(
      SnackbarType.error,
      message: message,
      title: title,
      duration: duration,
    );
  }

  /// Shows a success message.
  void showSuccess({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      SnackbarType.success,
      message: message,
      title: title,
      duration: duration,
    );
  }

  /// Shows an informational message.
  void showInfo({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      SnackbarType.info,
      message: message,
      title: title,
      duration: duration,
    );
  }

  /// Shows a warning message.
  void showWarning({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      SnackbarType.warning,
      message: message,
      title: title,
      duration: duration,
    );
  }

  void _show(
    SnackbarType type, {
    required String message,
    String? title,
    required Duration duration,
  }) {
    _messenger
      ..clearSnackBars()
      ..showSnackBar(
        buildAppSnackBar(
          type: type,
          message: message,
          title: title,
          duration: duration,
        ),
      );
  }
}
