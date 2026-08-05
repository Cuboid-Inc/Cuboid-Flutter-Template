import 'dart:io';

import 'package:cuboid_flutter_template/core/errors/failures.dart';
import 'package:cuboid_flutter_template/core/errors/result.dart';
import 'package:cuboid_flutter_template/core/config/env.dart';
import 'package:cuboid_flutter_template/main.logger.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = AppLogger('SupabaseGuard');

/// Runs [run] and maps thrown Supabase/network exceptions to a [Result].
///
/// Short-circuits when Supabase is unconfigured, so repositories never
/// check [Env.isConfigured] themselves.
Future<Result<T>> guard<T>(Future<T> Function() run) async {
  if (!Env.isConfigured) {
    _logger.e('Supabase configuration missing');
    return const Failure(
      ValidationFailure(
        'Supabase is not configured. Run with --dart-define-from-file=env/dev.json.',
      ),
    );
  }
  try {
    return Success(await run());
  } on AuthException catch (e) {
    _logger.e('Supabase auth operation failed', error: e);
    return Failure(AuthFailure(authMessage(e.code)));
  } on PostgrestException catch (e) {
    _logger.e('Supabase database operation failed', error: e);
    return const Failure(ServerFailure());
  } on FunctionException catch (e) {
    _logger.e('Supabase function operation failed', error: e);
    return const Failure(
      ServerFailure('The requested action failed. Please try again.'),
    );
  } on SocketException catch (e) {
    _logger.e('Supabase network operation failed', error: e);
    return const Failure(NetworkFailure());
  } catch (e, stackTrace) {
    _logger.e(
      'Unhandled Supabase operation failure',
      error: e,
      stackTrace: stackTrace,
    );
    return const Failure(UnknownFailure());
  }
}

@visibleForTesting
String authMessage(String? code) => switch (code) {
  'invalid_credentials' => 'Email or password is incorrect.',
  'email_provider_disabled' =>
    'Email sign-in is unavailable. Please contact your administrator.',
  'email_not_confirmed' => 'Confirm your email before signing in.',
  'weak_password' => 'Use a stronger password with at least 8 characters.',
  'over_request_rate_limit' => 'Too many attempts. Please wait and try again.',
  _ => 'Authentication failed. Please try again.',
};
