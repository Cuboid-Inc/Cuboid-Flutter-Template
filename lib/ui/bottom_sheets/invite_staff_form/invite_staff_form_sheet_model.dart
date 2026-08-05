import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/business_profile.dart';
import 'package:fleetgo/features/auth/data/auth_validation.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class InviteStaffFormSheetModel extends BaseViewModel {
  InviteStaffFormSheetModel({required this.completer, required this.request});

  final Function(SheetResponse response) completer;
  final SheetRequest request;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  List<AccessPack> selectedPacks = [];

  void selectPacks(List<AccessPack> packs) {
    selectedPacks = packs;
    notifyListeners();
  }

  void submit() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    if (name.isEmpty || !isValidEmail(email) || selectedPacks.isEmpty) return;
    completer(
      SheetResponse<StaffMember>(
        confirmed: true,
        data: StaffMember(
          id: '',
          name: name,
          email: email,
          accessPacks: selectedPacks.toSet(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
