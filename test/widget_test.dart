import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Cuboid Flutter Template'))),
    );
    expect(find.text('Cuboid Flutter Template'), findsOneWidget);
  });
}
