import 'package:cuboid_flutter_template/core/models/report_models.dart';
import 'package:cuboid_flutter_template/core/money.dart';

extension PartyBalanceRow on PartyBalance {
  static PartyBalance fromRow(Map<String, dynamic> row) => PartyBalance(
    partyId: row['party_id'] as String,
    amount: roundMoney(row['balance'] as num),
  );
}
