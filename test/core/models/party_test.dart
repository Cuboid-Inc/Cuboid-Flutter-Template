import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns initials from the first two words', () {
    expect(
      const Party(
        id: 'party-1',
        name: 'gulf star logistics',
        type: PartyType.customer,
      ).initials,
      'GS',
    );
  });
}
