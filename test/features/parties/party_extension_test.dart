import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/features/parties/data/party_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps and writes a party row', () {
    const party = Party(
      id: 'party-1',
      name: 'Gulf Star',
      type: PartyType.customer,
      address: 'Street 1',
      city: 'Dubai',
      country: 'UAE',
      trn: 'TRN-1',
      contactPerson: 'Aisha',
      phone: '+971500000000',
      email: 'aisha@example.com',
      paymentTerms: PaymentTerms.net30,
      notes: 'Note',
      isArchived: true,
    );

    final row = party.toRow('tenant-1');
    expect(row['tenant_id'], 'tenant-1');
    expect(row['type'], 'customer');
    expect(row['payment_terms'], 'net_30');
    expect(row['contact_person'], 'Aisha');

    final mapped = PartyRow.fromRow({
      ...row,
      'id': 'party-1',
      'is_archived': true,
    });
    expect(mapped.id, party.id);
    expect(mapped.type, PartyType.customer);
    expect(mapped.paymentTerms, PaymentTerms.net30);
    expect(mapped.isArchived, isTrue);
  });
}
