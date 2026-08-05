import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/agreement.dart';
import 'package:fleetgo/features/more/ui/agreement_detail/widgets/agreement_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AgreementInfoCard renders monthly and per-trip branches', (
    tester,
  ) async {
    final agreement = Agreement(
      id: 'a1',
      reference: 'AGR-1',
      name: 'Monthly hire',
      customerId: 'c1',
      rateModel: RateModel.monthly,
      baseRate: 1000,
      dutyDays: 26,
      includedHours: 208,
      overtimeRate: 20,
      extraDayRate: 50,
      extraTripRate: 75,
      startDate: DateTime(2026, 7, 1),
      notes: 'Contract note',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              AgreementInfoCard(
                agreement: agreement,
                customerName: 'Customer',
                vehicleLabel: 'Truck 1',
              ),
              AgreementInfoCard(
                agreement: Agreement(
                  id: 'a2',
                  reference: 'AGR-2',
                  name: 'Per trip',
                  customerId: 'c1',
                  rateModel: RateModel.perTrip,
                ),
                customerName: 'Customer',
                vehicleLabel: 'None',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('AGREEMENT DETAILS'), findsNWidgets(2));
    expect(find.text('Per Trip Rate'), findsOneWidget);
    expect(find.text('Monthly Hire'), findsOneWidget);
    expect(find.text('Duty Days / Month'), findsOneWidget);
    expect(find.text('${Formatters.money(20)} / hr'), findsOneWidget);
    expect(find.text('Contract note'), findsOneWidget);
  });
}
