import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/ui/dialogs/add_edit_extra/add_edit_extra_dialog_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stacked_services/stacked_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('submit rejects missing, invalid, and non-positive values', () {
    DialogResponse? saved;
    final model = AddEditExtraDialogModel(
      completer: (response) => saved = response,
      request: DialogRequest(),
    );

    model.nameController.text = 'Waiting';
    for (final amount in ['', 'invalid', '0', '-1']) {
      model.amountController.text = amount;
      model.submit();
      expect(saved, isNull);
    }
    model.dispose();
  });

  test('add mode submits trimmed name and amount', () {
    DialogResponse? saved;
    final model = AddEditExtraDialogModel(
      completer: (response) => saved = response,
      request: DialogRequest(),
    );
    model.nameController.text = ' Waiting ';
    model.amountController.text = '12.50';
    model.submit();

    expect(saved!.confirmed, isTrue);
    expect(saved!.data, {'name': 'Waiting', 'amount': 12.5});
    model.cancel();
    expect(saved!.confirmed, isFalse);
    model.dispose();
  });

  test('edit mode prefills positive amount and handles zero amount', () {
    final model = AddEditExtraDialogModel(
      completer: (_) {},
      request: DialogRequest(data: {'name': 'Waiting', 'amount': 12.5}),
    );
    expect(model.isEditing, isTrue);
    expect(model.nameController.text, 'Waiting');
    expect(model.amountController.text, Formatters.rawMoney(12.5));
    model.dispose();

    final zero = AddEditExtraDialogModel(
      completer: (_) {},
      request: DialogRequest(data: {'name': 'Waiting', 'amount': 0}),
    );
    expect(zero.isEditing, isTrue);
    expect(zero.amountController.text, isEmpty);
    zero.dispose();
  });
}
