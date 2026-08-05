import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/money.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/reports/data/report_type.dart';
import 'package:fleetgo/features/reports/data/reports_repository.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class ReportDetailViewModel extends BaseViewModel {
  ReportDetailViewModel({required this.type, required this.period});

  final ReportType type;
  final Period period;
  final _repository = locator<ReportsRepository>();
  final _snackbar = locator<SnackbarService>();
  List<(String, String, String)> rows = const [];
  num total = 0;
  String? errorMessage;

  Future<void> init() async {
    setBusy(true);
    errorMessage = null;
    switch (type) {
      case ReportType.profit:
        await _loadProfit();
      case ReportType.ownership:
        switch (await _repository.ownership(period)) {
          case Success(:final value):
            total = value.owned + value.external;
            rows = [
              (
                'Owned vehicles',
                'Customer revenue',
                Formatters.money(value.owned),
              ),
              (
                'External vehicles',
                'Customer revenue',
                Formatters.money(value.external),
              ),
            ];
          case Failure(:final failure):
            errorMessage = failure.message;
        }
      case ReportType.vehicleProfit:
        await _loadVehicleProfit();
      case ReportType.expenses:
        switch (await _repository.expenseSummary(period)) {
          case Success(:final value):
            total = value.fold<num>(
              0,
              (sum, row) => roundMoney(sum + row.amount),
            );
            rows = [
              for (final row in value)
                (
                  row.category.name,
                  'Operating expense',
                  Formatters.money(row.amount),
                ),
            ];
          case Failure(:final failure):
            errorMessage = failure.message;
        }
      case ReportType.cashbook:
        switch (await _repository.cashbook(period)) {
          case Success(:final value):
            total = value.net;
            rows = [
              (
                'Money in',
                'Cleared payments',
                Formatters.money(value.inAmount),
              ),
              (
                'Money out',
                'Cleared payments',
                Formatters.money(value.outAmount),
              ),
            ];
          case Failure(:final failure):
            errorMessage = failure.message;
        }
      case ReportType.unbilled:
        switch (await _repository.unbilledWork(period)) {
          case Success(:final value):
            total = value.fold<num>(
              0,
              (sum, row) => roundMoney(sum + row.workOrder.net),
            );
            rows = [
              for (final row in value)
                (
                  row.workOrder.number,
                  row.customerName,
                  Formatters.money(row.workOrder.net),
                ),
            ];
          case Failure(:final failure):
            errorMessage = failure.message;
        }
      case ReportType.unpaid:
        switch (await _repository.unpaidInvoices(period)) {
          case Success(:final value):
            total = value.fold<num>(
              0,
              (sum, row) => roundMoney(sum + row.balance),
            );
            rows = [
              for (final row in value)
                (
                  row.invoice.number,
                  row.invoice.buyerName,
                  Formatters.money(row.balance),
                ),
            ];
          case Failure(:final failure):
            errorMessage = failure.message;
        }
      case ReportType.expiry:
        switch (await _repository.expiringDocuments(period)) {
          case Success(:final value):
            rows = [
              for (final row in value)
                (row.ownerName, row.kind, Formatters.date(row.expiresOn)),
            ];
            total = rows.length;
          case Failure(:final failure):
            errorMessage = failure.message;
        }
    }
    setBusy(false);
  }

  Future<void> _loadProfit() async {
    final customers = await _repository.customers();
    final statements = await _repository.statementRows(period);
    final profit = await _repository.profit(period);
    switch (customers) {
      case Success(:final value):
        switch (statements) {
          case Success(value: final statementValue):
            rows = [
              for (final party in value)
                (
                  party.name,
                  'Customer',
                  Formatters.money(
                    statementValue
                        .where((row) => row.partyId == party.id)
                        .fold<num>(
                          0,
                          (sum, row) => roundMoney(sum + row.amount),
                        ),
                  ),
                ),
            ];
          case Failure(:final failure):
            errorMessage = failure.message;
        }
      case Failure(:final failure):
        errorMessage = failure.message;
    }
    switch (profit) {
      case Success(:final value):
        total = value;
      case Failure(:final failure):
        errorMessage = failure.message;
    }
  }

  Future<void> _loadVehicleProfit() async {
    final result = await _repository.vehicleProfit(period);
    final vehicles = await _repository.vehicles();
    switch (result) {
      case Success(:final value):
        switch (vehicles) {
          case Success(value: final vehicleValue):
            rows = [
              for (final row in value)
                (
                  vehicleValue
                      .firstWhere((vehicle) => vehicle.id == row.vehicleId)
                      .label,
                  'Revenue minus payable and expenses',
                  Formatters.money(row.profit),
                ),
            ];
            total = value.fold<num>(
              0,
              (sum, row) => roundMoney(sum + row.profit),
            );
          case Failure(:final failure):
            errorMessage = failure.message;
        }
      case Failure(:final failure):
        errorMessage = failure.message;
    }
  }

  void export() => _snackbar.showInfo('Available after backend connect');
}
