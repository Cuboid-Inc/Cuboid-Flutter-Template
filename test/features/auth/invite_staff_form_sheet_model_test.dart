import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/invite_staff_form/invite_staff_form_sheet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stacked_services/stacked_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('submit rejects missing name, invalid email, or access packs', () {
    StaffMember? saved;
    final model = InviteStaffFormSheetModel(
      completer: (response) => saved = response.data as StaffMember?,
      request: SheetRequest(),
    );

    model.nameController.text = 'Staff';
    model.emailController.text = 'invalid';
    model.selectPacks([AccessPack.operations]);
    model.submit();
    expect(saved, isNull);

    model.emailController.text = 'staff@example.com';
    model.selectPacks([]);
    model.submit();
    expect(saved, isNull);

    model.nameController.clear();
    model.selectPacks([AccessPack.operations]);
    model.submit();
    expect(saved, isNull);
    model.dispose();
  });

  test('selectPacks notifies and submit returns trimmed staff data', () {
    StaffMember? saved;
    final model = InviteStaffFormSheetModel(
      completer: (response) => saved = response.data as StaffMember?,
      request: SheetRequest(),
    );

    var notifications = 0;
    model.addListener(() => notifications++);
    model.nameController.text = ' Staff ';
    model.emailController.text = ' staff@example.com ';
    model.selectPacks([AccessPack.money, AccessPack.money, AccessPack.reports]);
    model.submit();

    expect(notifications, 1);
    expect(saved!.id, isEmpty);
    expect(saved!.name, 'Staff');
    expect(saved!.email, 'staff@example.com');
    expect(saved!.accessPacks, {AccessPack.money, AccessPack.reports});
    model.dispose();
  });
}
