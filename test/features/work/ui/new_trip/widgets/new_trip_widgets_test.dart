import 'package:cuboid_flutter_template/features/work/ui/new_trip/widgets/form_step_progress_bar.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/widgets/trip_total_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('TripTotalCard renders its total', (tester) async {
    await tester.pumpWidget(
      app(const TripTotalCard(formattedTotal: 'AED 125.00')),
    );
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('AED 125.00'), findsOneWidget);
  });

  testWidgets('FormStepProgressBar fills completed steps only', (tester) async {
    await tester.pumpWidget(app(const FormStepProgressBar(currentStep: 2)));
    expect(find.byType(Container), findsNWidgets(3));
  });
}
