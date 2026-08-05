import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/business_profile.dart';
import 'package:fleetgo/features/more/ui/staff_access/widgets/staff_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StaffRow renders owner and invited staff states', (
    tester,
  ) async {
    const owner = StaffMember(
      id: 'owner',
      name: 'Owner',
      email: 'owner@example.com',
      role: StaffRole.owner,
      accessPacks: {AccessPack.money},
    );
    const invited = StaffMember(
      id: 'staff',
      name: 'Staff',
      email: 'staff@example.com',
      status: StaffStatus.invited,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StaffRow(member: owner, packsLabel: (_) => 'Money access'),
              StaffRow(member: invited, packsLabel: (_) => 'No access'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Owner'), findsNWidgets(2));
    expect(find.text('Money access'), findsOneWidget);
    expect(find.text('Invited'), findsOneWidget);
  });
}
