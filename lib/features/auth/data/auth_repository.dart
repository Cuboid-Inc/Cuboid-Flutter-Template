import 'dart:async';

import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/core/supabase/env.dart';
import 'package:fleetgo/core/supabase/supabase_guard.dart';
import 'package:fleetgo/features/auth/data/auth_access_extension.dart';
import 'package:fleetgo/main.logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthDestination {
  signedOut,
  signedIn,
  passwordRecovery,
  invitation,
  accessUnavailable,
  linkExpired,
}

enum MembershipStatus { invited, active, suspended }

class AuthAccess {
  const AuthAccess({
    required this.memberId,
    required this.tenantId,
    required this.tenantName,
    required this.email,
    required this.displayName,
    required this.role,
    required this.status,
    required this.accessPacks,
  });

  final String memberId;
  final String tenantId;
  final String tenantName;
  final String email;
  final String displayName;
  final StaffRole role;
  final MembershipStatus status;
  final Set<AccessPack> accessPacks;

  bool get isOwner => role == StaffRole.owner;
}

class AuthStartup {
  const AuthStartup(this.destination, [this.access]);

  final AuthDestination destination;
  final AuthAccess? access;
}

class AuthRepository {
  static const redirectUrl = 'com.cuboidinc.fleetgo://auth-callback';

  final _logger = AppLogger('AuthRepository');
  String _demoEmail = 'owner@fleetgo.com';
  final _demoTenantName = 'FleetGo Owner';
  AuthAccess? currentAccess;

  String get currentEmail => Env.isConfigured
      ? (Supabase.instance.client.auth.currentUser?.email ?? '')
      : _demoEmail;

  String get currentTenantName =>
      Env.isConfigured ? currentAccess?.tenantName ?? '' : _demoTenantName;

  Future<Result<AuthStartup>> resolveStartup() async {
    if (!Env.isConfigured) {
      return const Success(AuthStartup(AuthDestination.signedOut));
    }

    AuthState state;
    try {
      state = await Supabase.instance.client.auth.onAuthStateChange.first
          .timeout(
            const Duration(seconds: 1),
            onTimeout: () => AuthState(
              AuthChangeEvent.initialSession,
              Supabase.instance.client.auth.currentSession,
            ),
          );
    } on AuthException catch (error) {
      _logger.w('Startup auth callback was rejected', error: error);
      return const Success(AuthStartup(AuthDestination.linkExpired));
    }

    if (state.event == AuthChangeEvent.passwordRecovery) {
      return const Success(AuthStartup(AuthDestination.passwordRecovery));
    }
    if (state.session == null) {
      return const Success(AuthStartup(AuthDestination.signedOut));
    }

    return _resolveAccess();
  }

  Future<Result<AuthStartup>> signIn({
    required String email,
    required String password,
  }) async {
    _demoEmail = email;
    if (!Env.isConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return const Success(AuthStartup(AuthDestination.signedIn));
    }
    final signInResult = await guard(
      () => Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      ),
    );
    if (signInResult case Failure()) return Failure(signInResult.failure);
    return _resolveAccess();
  }

  Future<Result<void>> signOut() async {
    currentAccess = null;
    if (!Env.isConfigured) return const Success(null);
    final result = await guard(() => Supabase.instance.client.auth.signOut());
    if (result case Success()) _logger.i('Signed out');
    return result;
  }

  Future<Result<void>> sendPasswordReset(String email) async {
    if (!Env.isConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return const Success(null);
    }
    return guard(
      () => Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      ),
    );
  }

  Future<Result<void>> resetPassword(String newPassword) async {
    if (!Env.isConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return const Success(null);
    }
    final result = await guard(
      () => Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      ),
    );
    if (result case Success()) {
      await Supabase.instance.client.auth.signOut();
      _logger.i('Password reset completed');
    }
    return switch (result) {
      Success() => const Success(null),
      Failure(:final failure) => Failure(failure),
    };
  }

  Future<Result<AuthStartup>> acceptInvitation({
    required String email,
    required String password,
  }) async {
    if (!Env.isConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return const Success(AuthStartup(AuthDestination.signedIn));
    }

    if (currentEmail.toLowerCase() != email.toLowerCase()) {
      return const Failure(
        AuthFailure('This invitation belongs to another email address.'),
      );
    }

    final result = await guard(() async {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      await Supabase.instance.client.rpc<bool>('accept_invitation');
    });
    if (result case Failure()) return Failure(result.failure);
    _logger.i('Invitation accepted');
    return _resolveAccess();
  }

  Future<Result<AuthStartup>> _resolveAccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      currentAccess = null;
      return const Success(AuthStartup(AuthDestination.signedOut));
    }

    final result = await guard<AuthAccess?>(() async {
      final row = await Supabase.instance.client
          .from('tenant_members')
          .select(
            'id, tenant_id, email, display_name, role, status, '
            'tenants(name), member_access_packs(pack)',
          )
          .eq('user_id', user.id)
          .maybeSingle();
      return row == null ? null : AuthAccessRow.fromRow(row);
    });

    switch (result) {
      case Failure(:final failure):
        return Failure(failure);
      case Success(value: null):
        currentAccess = null;
        _logger.w('Authenticated user has no tenant access');
        return const Success(AuthStartup(AuthDestination.accessUnavailable));
      case Success(:final value):
        final access = value!;
        currentAccess = access;
        _logger.i('Tenant access resolved with status ${access.status.name}');
        return Success(
          AuthStartup(switch (access.status) {
            MembershipStatus.active when access.tenantName.isNotEmpty =>
              AuthDestination.signedIn,
            MembershipStatus.active => AuthDestination.accessUnavailable,
            MembershipStatus.invited => AuthDestination.invitation,
            MembershipStatus.suspended => AuthDestination.accessUnavailable,
          }, access),
        );
    }
  }
}
