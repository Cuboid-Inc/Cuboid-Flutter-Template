import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/failures.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/core/models/report_models.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/reports/data/report_type.dart';
import 'package:fleetgo/features/reports/data/reports_repository.dart';
import 'package:fleetgo/features/reports/ui/report_detail/report_detail_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/stacked_service_mocks.dart';

class MockReportsRepository extends Mock implements ReportsRepository {}

final period = Period.month(2026, 7);
Party party(String id, String name) =>
    Party(id: id, name: name, type: PartyType.customer);
Vehicle vehicle(String id, String label) => Vehicle(
  id: id,
  plateNumber: id,
  label: label,
  vehicleClass: VehicleClass.threeTon,
  ownership: VehicleOwnership.owned,
);
WorkOrder work(String id, String number) => WorkOrder(
  id: id,
  number: number,
  customerId: 'c',
  date: DateTime(2026, 7, 2),
  pickup: 'A',
  destination: 'B',
  chargeLines: [const ChargeLine(name: 'Trip', unitPrice: 100)],
);

void main() {
  late MockReportsRepository repository;
  late MockSnackbarService snackbar;
  setUp(() {
    repository = MockReportsRepository();
    snackbar = MockSnackbarService();
    replaceTestRegistration<ReportsRepository>(repository);
    replaceTestRegistration<SnackbarService>(snackbar);
  });
  tearDown(locator.reset);

  test('loads profit and ownership reports', () async {
    when(
      () => repository.customers(),
    ).thenAnswer((_) async => Success([party('c', 'Customer')]));
    when(() => repository.statementRows(period)).thenAnswer(
      (_) async => Success([
        StatementRow(
          partyId: 'c',
          date: period.start,
          workOrderId: 'w',
          description: 'Trip',
          amount: 100,
        ),
      ]),
    );
    when(
      () => repository.profit(period),
    ).thenAnswer((_) async => const Success(80));
    final profit = ReportDetailViewModel(
      type: ReportType.profit,
      period: period,
    );
    await profit.init();
    expect(profit.total, 80);
    expect(profit.rows.single.$1, 'Customer');
    when(() => repository.ownership(period)).thenAnswer(
      (_) async => const Success(OwnershipSplit(owned: 70, external: 30)),
    );
    final ownership = ReportDetailViewModel(
      type: ReportType.ownership,
      period: period,
    );
    await ownership.init();
    expect(ownership.total, 100);
    expect(ownership.rows, hasLength(2));
  });

  test('loads remaining report types', () async {
    when(() => repository.vehicleProfit(period)).thenAnswer(
      (_) async => const Success([
        VehicleProfit(vehicleId: 'v', revenue: 100, payable: 20, expense: 10),
      ]),
    );
    when(
      () => repository.vehicles(),
    ).thenAnswer((_) async => Success([vehicle('v', 'Truck')]));
    final vehicleModel = ReportDetailViewModel(
      type: ReportType.vehicleProfit,
      period: period,
    );
    await vehicleModel.init();
    expect(vehicleModel.total, 70);
    when(() => repository.expenseSummary(period)).thenAnswer(
      (_) async => const Success([
        ExpenseTotal(ExpenseCategory.fuel, 12),
        ExpenseTotal(ExpenseCategory.toll, 3),
      ]),
    );
    final expenses = ReportDetailViewModel(
      type: ReportType.expenses,
      period: period,
    );
    await expenses.init();
    expect(expenses.total, 15);
    when(() => repository.cashbook(period)).thenAnswer(
      (_) async => const Success(CashbookTotals(inAmount: 100, outAmount: 25)),
    );
    final cashbook = ReportDetailViewModel(
      type: ReportType.cashbook,
      period: period,
    );
    await cashbook.init();
    expect(cashbook.total, 75);
    final invoice = Invoice(
      id: 'i',
      number: 'INV-1',
      buyerId: 'c',
      buyerName: 'Customer',
      issueDate: period.start,
    );
    when(() => repository.unbilledWork(period)).thenAnswer(
      (_) async => Success([
        UnbilledWorkRow(workOrder: work('w', 'WO-1'), customerName: 'Customer'),
      ]),
    );
    when(() => repository.unpaidInvoices(period)).thenAnswer(
      (_) async => Success([UnpaidInvoiceRow(invoice: invoice, balance: 50)]),
    );
    when(() => repository.expiringDocuments(period)).thenAnswer(
      (_) async => Success([
        ExpiringDocument(
          ownerId: 'v',
          ownerName: 'Truck',
          ownerType: 'vehicle',
          kind: 'Insurance',
          expiresOn: DateTime(2026, 7, 10),
        ),
      ]),
    );
    final unbilled = ReportDetailViewModel(
      type: ReportType.unbilled,
      period: period,
    );
    await unbilled.init();
    expect(unbilled.total, 100);
    final unpaid = ReportDetailViewModel(
      type: ReportType.unpaid,
      period: period,
    );
    await unpaid.init();
    expect(unpaid.total, 50);
    final expiry = ReportDetailViewModel(
      type: ReportType.expiry,
      period: period,
    );
    await expiry.init();
    expect(expiry.total, 1);
    expiry.export();
  });

  test('propagates report failures', () async {
    when(() => repository.ownership(period)).thenAnswer(
      (_) async => const Failure(ValidationFailure('report failed')),
    );
    final model = ReportDetailViewModel(
      type: ReportType.ownership,
      period: period,
    );
    await model.init();
    expect(model.errorMessage, 'report failed');
    when(() => repository.customers()).thenAnswer(
      (_) async => const Failure(ValidationFailure('customers failed')),
    );
    when(
      () => repository.statementRows(period),
    ).thenAnswer((_) async => const Success([]));
    when(() => repository.profit(period)).thenAnswer(
      (_) async => const Failure(ValidationFailure('profit failed')),
    );
    final profit = ReportDetailViewModel(
      type: ReportType.profit,
      period: period,
    );
    await profit.init();
    expect(profit.errorMessage, 'profit failed');
    when(() => repository.vehicleProfit(period)).thenAnswer(
      (_) async => const Failure(ValidationFailure('vehicle failed')),
    );
    when(
      () => repository.vehicles(),
    ).thenAnswer((_) async => const Success([]));
    final vehicle = ReportDetailViewModel(
      type: ReportType.vehicleProfit,
      period: period,
    );
    await vehicle.init();
    expect(vehicle.errorMessage, 'vehicle failed');
  });
}
