import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/payment.dart';
import 'package:fleetgo/core/models/settlement.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/money/data/money_repository.dart';
import 'package:fleetgo/features/money/ui/balance_detail/balance_detail_viewmodel.dart';
import '../../helpers/stacked_service_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

void main() {
  late MockMoneyRepository moneyRepository;
  late MockSnackbarService snackbarService;
  late MockNavigationService navigationService;

  setUp(() {
    moneyRepository = MockMoneyRepository();
    snackbarService = MockSnackbarService();
    navigationService = MockNavigationService();

    replaceTestRegistration<SnackbarService>(snackbarService);
    replaceTestRegistration<NavigationService>(navigationService);
  });

  tearDown(() {
    locator.reset();
  });

  test(
    'init loads invoices and payments and compiles timeline for customer',
    () async {
      final party = Party(
        id: 'c1',
        name: 'Marina Build Co',
        type: PartyType.customer,
      );

      final invoice = Invoice(
        id: 'i1',
        number: 'INV-101',
        buyerId: 'c1',
        buyerName: 'Marina Build Co',
        issueDate: DateTime(2026, 6, 1),
        dueDate: DateTime(2026, 6, 15),
        lines: const [
          InvoiceLine(name: 'Trip', unitPrice: 2000.00, quantity: 1),
        ],
      );

      final payment = Payment(
        id: 'p1',
        direction: PaymentDirection.incoming,
        partyId: 'c1',
        date: DateTime(2026, 6, 10),
        amount: 1500.00,
        method: PaymentMethod.cheque,
      );

      when(
        () => moneyRepository.fetchInvoices(),
      ).thenAnswer((_) async => Success([invoice]));
      when(
        () => moneyRepository.fetchSettlements(),
      ).thenAnswer((_) async => const Success(<SupplierSettlement>[]));
      when(
        () => moneyRepository.fetchPayments(),
      ).thenAnswer((_) async => Success([payment]));

      final model = BalanceDetailViewModel(party, repository: moneyRepository);

      await model.init();

      // 2100.00 gross (2000.00 net + 100.00 VAT at 5%)
      // - 1500.00 payment
      // Running balance should be 600.00
      expect(model.currentBalance, 600.00);
      expect(model.activityItems, hasLength(2));
      expect(
        model.activityItems.first.runningBalance,
        600.00,
      ); // Reversed (newest first)
    },
  );
}
