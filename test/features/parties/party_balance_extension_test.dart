import 'package:cuboid_flutter_template/features/parties/data/party_balance_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps and rounds a party balance row', () {
    final balance = PartyBalanceRow.fromRow({
      'party_id': 'party-1',
      'balance': 10.005,
    });

    expect(balance.partyId, 'party-1');
    expect(balance.amount, 10.01);
  });
}
