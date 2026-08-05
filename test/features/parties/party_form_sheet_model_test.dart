import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/ui/bottom_sheets/party_form/party_form_sheet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stacked_services/stacked_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('submit rejects a missing party name', () {
    Party? savedParty;
    final model = PartyFormSheetModel(
      completer: (response) => savedParty = response.data as Party?,
      request: SheetRequest(),
    );

    model.submit();

    expect(savedParty, isNull);
    model.dispose();
  });

  test('selection methods update type and payment terms', () {
    final model = PartyFormSheetModel(
      completer: (_) {},
      request: SheetRequest(),
    );

    model.selectType([PartyType.supplier]);
    model.selectPaymentTerms(PaymentTerms.net30);
    expect(model.type, PartyType.supplier);
    expect(model.paymentTerms, PaymentTerms.net30);

    model.selectPaymentTerms(null);
    expect(model.paymentTerms, PaymentTerms.net30);
    model.dispose();
  });

  test('submit returns trimmed optional fields and default country', () {
    Party? saved;
    final model = PartyFormSheetModel(
      completer: (response) => saved = response.data as Party?,
      request: SheetRequest(),
    );
    model.nameController.text = ' Customer ';
    model.trnController.text = ' TRN ';
    model.phoneController.text = ' ';
    model.countryController.clear();
    model.emailController.text = ' email@example.com ';
    model.submit();

    expect(saved, isNotNull);
    expect(saved!.name, 'Customer');
    expect(saved!.trn, 'TRN');
    expect(saved!.phone, isNull);
    expect(saved!.email, 'email@example.com');
    expect(saved!.country, 'United Arab Emirates');
    model.dispose();
  });

  test('edit mode prefills fields and preserves party id', () {
    final initial = Party(
      id: 'p1',
      name: 'Existing',
      type: PartyType.supplier,
      trn: 'TRN',
      phone: '050',
      address: 'Address',
      city: 'Dubai',
      country: 'UAE',
      contactPerson: 'Contact',
      email: 'old@example.com',
      paymentTerms: PaymentTerms.net15,
      notes: 'Note',
    );
    Party? saved;
    final model = PartyFormSheetModel(
      completer: (response) => saved = response.data as Party?,
      request: SheetRequest(data: initial),
    );

    expect(model.isEditing, isTrue);
    expect(model.nameController.text, 'Existing');
    expect(model.countryController.text, 'UAE');
    expect(model.paymentTerms, PaymentTerms.net15);
    model.submit();
    expect(saved!.id, 'p1');
    expect(saved!.type, PartyType.supplier);
    expect(saved!.notes, 'Note');
    model.dispose();
  });
}
