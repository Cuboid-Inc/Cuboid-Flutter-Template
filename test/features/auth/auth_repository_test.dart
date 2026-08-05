import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unconfigured auth uses the local startup flow', () async {
    final repository = AuthRepository();

    expect(repository.currentEmail, 'owner@fleetgo.com');
    expect(repository.currentTenantName, 'FleetGo Owner');
    expect(
      (await repository.resolveStartup() as Success<AuthStartup>)
          .value
          .destination,
      AuthDestination.signedOut,
    );

    final signedIn = await repository.signIn(
      email: 'owner@example.com',
      password: 'password',
    );
    expect(
      (signedIn as Success<AuthStartup>).value.destination,
      AuthDestination.signedIn,
    );
    expect(repository.currentEmail, 'owner@example.com');

    expect(
      await repository.sendPasswordReset(repository.currentEmail),
      isA<Success<void>>(),
    );
    expect(
      await repository.resetPassword('new-password'),
      isA<Success<void>>(),
    );
    expect(
      (await repository.acceptInvitation(
                email: 'other@example.com',
                password: 'password',
              )
              as Success<AuthStartup>)
          .value
          .destination,
      AuthDestination.signedIn,
    );

    repository.currentAccess = const AuthAccess(
      memberId: 'member',
      tenantId: 'tenant',
      tenantName: 'Tenant',
      email: 'owner@example.com',
      displayName: 'Owner',
      role: StaffRole.owner,
      status: MembershipStatus.active,
      accessPacks: {AccessPack.operations},
    );
    expect(repository.currentAccess!.isOwner, isTrue);
    expect(await repository.signOut(), isA<Success<void>>());
    expect(repository.currentAccess, isNull);
    expect(repository.currentTenantName, 'Cuboid Flutter Template Owner');
  });

  test('AuthAccess reports staff ownership correctly', () {
    const access = AuthAccess(
      memberId: 'member',
      tenantId: 'tenant',
      tenantName: 'Tenant',
      email: 'staff@example.com',
      displayName: 'Staff',
      role: StaffRole.staff,
      status: MembershipStatus.invited,
      accessPacks: {},
    );

    expect(access.isOwner, isFalse);
    expect(
      const AuthStartup(AuthDestination.invitation, access).access,
      access,
    );
  });
}
