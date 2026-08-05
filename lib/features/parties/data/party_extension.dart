import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';

extension PartyRow on Party {
  Map<String, dynamic> toRow(String tenantId) => {
    'tenant_id': tenantId,
    'name': name,
    'type': type.toJson(),
    'address': address,
    'city': city,
    'country': country,
    'trn': trn,
    'contact_person': contactPerson,
    'phone': phone,
    'email': email,
    'payment_terms': paymentTerms.toJson(),
    'notes': notes,
  };

  static Party fromRow(Map<String, dynamic> row) => Party(
    id: row['id'] as String,
    name: row['name'] as String,
    type: enumFromJson(row['type'] as String, PartyType.values),
    address: row['address'] as String?,
    city: row['city'] as String?,
    country: row['country'] as String,
    trn: row['trn'] as String?,
    contactPerson: row['contact_person'] as String?,
    phone: row['phone'] as String?,
    email: row['email'] as String?,
    paymentTerms: enumFromJson(
      row['payment_terms'] as String,
      PaymentTerms.values,
    ),
    notes: row['notes'] as String?,
    isArchived: row['is_archived'] as bool,
  );
}
