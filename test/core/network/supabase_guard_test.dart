import 'dart:io';

import 'package:nemara_homes/core/errors/failures.dart';
import 'package:nemara_homes/core/errors/result.dart';
import 'package:nemara_homes/core/config/env.dart';
import 'package:nemara_homes/core/network/supabase_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps disabled email sign-in to an actionable message', () {
    expect(
      authMessage('email_provider_disabled'),
      'Email sign-in is unavailable. Please contact your administrator.',
    );
  });

  test('maps every known auth error code', () {
    expect(
      authMessage('invalid_credentials'),
      'Email or password is incorrect.',
    );
    expect(
      authMessage('email_not_confirmed'),
      'Confirm your email before signing in.',
    );
    expect(
      authMessage('weak_password'),
      'Use a stronger password with at least 8 characters.',
    );
    expect(
      authMessage('over_request_rate_limit'),
      'Too many attempts. Please wait and try again.',
    );
    expect(authMessage(null), 'Authentication failed. Please try again.');
  });

  // Tests run without --dart-define, so Env.isConfigured is false.
  test(
    'guard short-circuits with ValidationFailure when unconfigured',
    () async {
      if (Env.isConfigured) return;
      var ran = false;
      final result = await guard(() async {
        ran = true;
        return 1;
      });

      expect(ran, isFalse, reason: 'run() must not execute without config');
      expect(result, isA<Failure<int>>());
      expect((result as Failure<int>).failure, isA<ValidationFailure>());
    },
  );

  test('maps Supabase and network exceptions', () async {
    if (!Env.isConfigured) return;

    final auth = await guard<int>(
      () async => throw const AuthException(
        'Bad credentials',
        code: 'invalid_credentials',
      ),
    );
    expect((auth as Failure<int>).failure, isA<AuthFailure>());
    expect(auth.failure.message, 'Email or password is incorrect.');

    final postgrest = await guard<int>(
      () async => throw const PostgrestException(message: 'Database error'),
    );
    expect((postgrest as Failure<int>).failure, isA<ServerFailure>());

    final function = await guard<int>(
      () async => throw const FunctionException(status: 500, details: 'Failed'),
    );
    expect((function as Failure<int>).failure, isA<ServerFailure>());
    expect(
      function.failure.message,
      'The requested action failed. Please try again.',
    );

    final network = await guard<int>(
      () async => throw const SocketException('Offline'),
    );
    expect((network as Failure<int>).failure, isA<NetworkFailure>());

    final unknown = await guard<int>(() async => throw StateError('Unknown'));
    expect((unknown as Failure<int>).failure, isA<UnknownFailure>());
  });
}
