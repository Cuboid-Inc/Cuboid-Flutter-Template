import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/features/more/ui/driver_detail/widgets/driver_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DriverInfoCard renders expiry and employment branches', (
    tester,
  ) async {
    final soon = DateTime.now().add(const Duration(days: 10));
    final driver = Driver(
      id: 'd1',
      name: 'Driver One',
      phone: '123',
      licenceNumber: 'L1',
      licenceExpiry: soon,
      identityReference: 'ID1',
      identityExpiry: DateTime.now().add(const Duration(days: 60)),
      employment: Responsibility.customer,
      notes: 'Good driver',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverInfoCard(driver: driver, supplierName: 'Supplier'),
        ),
      ),
    );
    expect(find.text('DRIVER INFORMATION'), findsOneWidget);
    expect(find.text('Subcontracted'), findsOneWidget);
    expect(find.text('Supplier'), findsOneWidget);
    expect(
      find.text('${Formatters.date(soon)} (Expiring soon)'),
      findsOneWidget,
    );
    expect(find.text(Formatters.date(driver.identityExpiry!)), findsOneWidget);
    expect(find.text('Good driver'), findsOneWidget);

    final operator = Driver(id: 'd2', name: 'Operator');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverInfoCard(driver: operator, supplierName: 'Supplier'),
        ),
      ),
    );
    expect(find.text('Operator'), findsNWidgets(2));
    expect(find.text('Supplier'), findsNothing);
  });
}
