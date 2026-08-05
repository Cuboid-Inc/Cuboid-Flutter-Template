import 'package:fleetgo/core/forms/form_validators.dart';
import 'package:fleetgo/ui/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates common form fields', () {
    expect(FormValidators.required('', label: 'Name'), 'Name is required');
    expect(FormValidators.required('Fleet', label: 'Name'), isNull);

    expect(FormValidators.email('invalid'), 'A valid email is required');
    expect(FormValidators.email('ops@fleet.com'), isNull);
    expect(FormValidators.email('', optional: true), isNull);

    expect(FormValidators.phone('abc'), 'Enter a valid phone number');
    expect(FormValidators.phone('+971 50 123 4567'), isNull);

    expect(FormValidators.money('0'), 'Enter a valid amount greater than 0');
    expect(FormValidators.money('10.50'), isNull);
    expect(
      FormValidators.money('11', max: 10, maxMessage: 'Too high'),
      'Too high',
    );

    expect(
      FormValidators.integerRange('32', label: 'Days', min: 0, max: 31),
      'Days must be a whole number from 0 to 31',
    );
    expect(
      FormValidators.numberRange('101', label: 'Margin', min: 0, max: 100),
      'Margin must be a number from 0 to 100',
    );

    expect(FormValidators.selection(null, 'Select a party'), 'Select a party');
    expect(FormValidators.selection('party', 'Select a party'), isNull);
  });

  testWidgets('AppTextField reports validation through FormState', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppTextField(
              label: 'Name',
              validator: (value) =>
                  FormValidators.required(value, label: 'Name'),
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Name is required'), findsOneWidget);
  });
}
