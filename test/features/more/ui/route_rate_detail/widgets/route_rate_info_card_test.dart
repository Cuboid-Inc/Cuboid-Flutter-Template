import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/route_rate.dart';
import 'package:fleetgo/features/more/ui/route_rate_detail/widgets/route_rate_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RouteRateInfoCard renders default extras', (tester) async {
    final routeRate = RouteRate(
      id: 'r1',
      appliesTo: 'Gulf Star',
      pickup: 'Dubai',
      destination: 'Al Ain',
      vehicleClass: VehicleClass.sevenTon,
      rate: 500,
      defaultExtras: const {'Waiting': 25},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RouteRateInfoCard(routeRate: routeRate)),
      ),
    );
    expect(find.text('ROUTE RATE DETAILS'), findsOneWidget);
    expect(find.text('7-Ton'), findsOneWidget);
    expect(find.text(Formatters.money(500)), findsOneWidget);
    expect(find.text('DEFAULT EXTRAS'), findsOneWidget);
    expect(find.text(Formatters.money(25)), findsOneWidget);
  });
}
