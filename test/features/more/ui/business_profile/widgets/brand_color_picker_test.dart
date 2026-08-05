import 'package:cuboid_flutter_template/features/more/ui/business_profile/widgets/brand_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BrandColorPicker marks and changes a swatch', (tester) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrandColorPicker(
            value: 0xFF11B2F3,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );
    expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
    await tester.tap(find.byType(GestureDetector).at(2));
    expect(selected, 0xFF0D9488);
  });
}
