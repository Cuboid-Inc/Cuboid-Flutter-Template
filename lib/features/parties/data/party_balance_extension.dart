import 'package:fleetgo/core/models/report_models.dart';
import 'package:fleetgo/core/money.dart';

extension PartyBalanceRow on PartyBalance {
  static PartyBalance fromRow(Map<String, dynamic> row) => PartyBalance(
    partyId: row['party_id'] as String,
    amount: roundMoney(row['balance'] as num),
  );
}
