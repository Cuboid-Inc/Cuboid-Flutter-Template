import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class ConfirmDialogModel extends BaseViewModel {
  ConfirmDialogModel({required this.completer});

  final Function(DialogResponse response) completer;

  void confirm() => completer(DialogResponse(confirmed: true));

  void cancel() => completer(DialogResponse());
}
