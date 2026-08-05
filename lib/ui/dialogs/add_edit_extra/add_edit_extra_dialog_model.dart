import 'package:fleetgo/core/config/formatters.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class AddEditExtraDialogModel extends BaseViewModel {
  AddEditExtraDialogModel({required this.completer, required this.request}) {
    // Pre-fill when editing an existing extra.
    final data = request.data as Map<String, dynamic>?;
    if (data != null) {
      nameController.text = (data['name'] as String?) ?? '';
      final amount = data['amount'] as num?;
      if (amount != null && amount > 0) {
        amountController.text = Formatters.rawMoney(amount);
      }
      isEditing = data.containsKey('name');
    }
  }

  final Function(DialogResponse response) completer;
  final DialogRequest request;

  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isEditing = false;

  void submit() {
    final name = nameController.text.trim();
    final amount = Formatters.parseMoney(amountController.text.trim()) ?? 0;
    if (name.isEmpty || amount <= 0) return;
    completer(
      DialogResponse(confirmed: true, data: {'name': name, 'amount': amount}),
    );
  }

  void cancel() => completer(DialogResponse(confirmed: false));

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }
}
