import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class PartyFormSheetModel extends BaseViewModel {
  PartyFormSheetModel({required this.completer, required this.request}) {
    if (request.data is Party) {
      final initialParty = request.data as Party;
      nameController.text = initialParty.name;
      trnController.text = initialParty.trn ?? '';
      phoneController.text = initialParty.phone ?? '';
      addressController.text = initialParty.address ?? '';
      cityController.text = initialParty.city ?? '';
      countryController.text = initialParty.country;
      contactPersonController.text = initialParty.contactPerson ?? '';
      emailController.text = initialParty.email ?? '';
      notesController.text = initialParty.notes ?? '';
      type = initialParty.type;
      paymentTerms = initialParty.paymentTerms;
    }
  }

  final Function(SheetResponse response) completer;
  final SheetRequest request;

  bool get isEditing => request.data is Party;

  final nameController = TextEditingController();
  final trnController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final countryController = TextEditingController(text: 'United Arab Emirates');
  final contactPersonController = TextEditingController();
  final emailController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  PartyType type = PartyType.customer;
  PaymentTerms paymentTerms = PaymentTerms.onReceipt;

  void selectType(List<PartyType> values) {
    type = values.first;
    notifyListeners();
  }

  void selectPaymentTerms(PaymentTerms? val) {
    if (val != null) {
      paymentTerms = val;
      notifyListeners();
    }
  }

  void submit() {
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final initialParty = request.data is Party ? request.data as Party : null;
    completer(
      SheetResponse<Party>(
        confirmed: true,
        data: Party(
          id: initialParty?.id ?? '',
          name: name,
          type: type,
          trn: _optional(trnController.text),
          phone: _optional(phoneController.text),
          address: _optional(addressController.text),
          city: _optional(cityController.text),
          country: countryController.text.trim().isEmpty
              ? 'United Arab Emirates'
              : countryController.text.trim(),
          contactPerson: _optional(contactPersonController.text),
          email: _optional(emailController.text),
          paymentTerms: paymentTerms,
          notes: _optional(notesController.text),
        ),
      ),
    );
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    nameController.dispose();
    trnController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    countryController.dispose();
    contactPersonController.dispose();
    emailController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
