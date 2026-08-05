import 'package:fleetgo/core/enums/enums.dart';

class Party {
  const Party({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.city,
    this.country = 'United Arab Emirates',
    this.trn,
    this.contactPerson,
    this.phone,
    this.email,
    this.paymentTerms = PaymentTerms.onReceipt,
    this.notes,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final PartyType type;
  final String? address;
  final String? city;
  final String country;
  final String? trn;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final PaymentTerms paymentTerms;
  final String? notes;
  final bool isArchived;

  String get initials => name
      .split(' ')
      .where((value) => value.isNotEmpty)
      .take(2)
      .map((value) => value[0])
      .join()
      .toUpperCase();
}
