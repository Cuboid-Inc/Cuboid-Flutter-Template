import 'package:cuboid_flutter_template/ui/dialogs/confirm/confirm_dialog_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stacked_services/stacked_services.dart';

void main() {
  test('confirm and cancel return the expected responses', () {
    final responses = <DialogResponse>[];
    final model = ConfirmDialogModel(completer: responses.add);

    model.confirm();
    model.cancel();

    expect(responses, hasLength(2));
    expect(responses[0].confirmed, isTrue);
    expect(responses[1].confirmed, isFalse);
  });
}
