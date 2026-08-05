import 'package:fleetgo/app/app.bottomsheets.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/dev/seed_demo_data.dart' as dev_seed;
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/expense.dart';
import 'package:fleetgo/core/models/payment.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/home/data/home_repository.dart';
import 'package:fleetgo/features/money/data/money_repository.dart';
import 'package:fleetgo/features/shell/shell_service.dart';
import 'package:fleetgo/ui/bottom_sheets/payment_form/payment_form_sheet_model.dart';
import 'package:fleetgo/ui/bottom_sheets/period/period_sheet_model.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum HomeBusy { addExpense, recordPayment, seedDemoData }

class AttentionItem {
  const AttentionItem({
    required this.count,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final int count;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}

class HomeViewModel extends ReactiveViewModel {
  HomeViewModel([HomeRepository? repository, MoneyRepository? moneyRepository])
    : _repository = repository ?? locator<HomeRepository>(),
      _moneyRepository = moneyRepository ?? locator<MoneyRepository>();

  final HomeRepository _repository;
  final MoneyRepository _moneyRepository;
  final _authRepository = locator<AuthRepository>();
  final _snackbar = locator<SnackbarService>();
  final _bottomSheets = locator<BottomSheetService>();
  final _navigation = locator<NavigationService>();
  final _shellService = locator<ShellService>();

  HomeSummary? _summary;
  Period _period = Period.thisMonth();
  String? errorMessage;

  @override
  List<ListenableServiceMixin> get listenableServices => [_shellService];

  bool get hasMoneyPermission {
    final access = _authRepository.currentAccess;
    return access?.isOwner == true ||
        access?.accessPacks.contains(AccessPack.money) == true;
  }

  bool get hasOperationsPermission {
    final access = _authRepository.currentAccess;
    return access?.isOwner == true ||
        access?.accessPacks.contains(AccessPack.operations) == true;
  }

  bool get hasReportsPermission {
    final access = _authRepository.currentAccess;
    return access?.isOwner == true ||
        access?.accessPacks.contains(AccessPack.reports) == true;
  }

  HomeSummary? get summary => _summary;

  String get tenantName {
    final name = _authRepository.currentTenantName;
    return name.isEmpty ? 'FleetGo' : name;
  }

  String get greeting {
    final hour = DateTime.now().hour;
    final period = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final access = _authRepository.currentAccess;
    final roleLabel = access == null
        ? ''
        : access.isOwner
        ? 'Owner'
        : access.accessPacks.isEmpty
        ? 'Staff'
        : access.accessPacks.map((pack) => pack.label).join(' · ');
    return roleLabel.isEmpty ? period : '$period, $roleLabel';
  }

  bool get hasCustomPeriod => _period != Period.thisMonth();

  String get periodLabel => Formatters.monthYear(_period.start);
  String get periodShort =>
      periodLabel.replaceFirst(' ${_period.start.year}', '').toUpperCase();
  String get profit => Formatters.money(_summary?.profit ?? 0);
  String get resultLabel => (_summary?.profit ?? 0) < 0 ? 'Loss' : 'Profit';
  String get resultAmount => Formatters.signedMoney((_summary?.profit ?? 0));
  String get resultExplanation => (_summary?.profit ?? 0) < 0
      ? 'Operating costs are higher than revenue'
      : 'Revenue is higher than operating costs';
  String get billed => Formatters.money(_summary?.billed ?? 0);
  String get revenue => Formatters.money(_summary?.revenue ?? 0);
  String get operatingCosts => Formatters.money(_summary?.operatingCosts ?? 0);
  String get received => Formatters.money(_summary?.received ?? 0);
  String get paidOut => Formatters.money(_summary?.paidOut ?? 0);
  String get cashFlow => Formatters.signedMoney(_summary?.cashFlow ?? 0);
  String get cashFlowExplanation => (_summary?.cashFlow ?? 0) < 0
      ? 'More money went out than came in'
      : (_summary?.cashFlow ?? 0) > 0
      ? 'More money came in than went out'
      : 'Money in and money out are equal';
  String get billedRaw => Formatters.rawMoney(_summary?.billed ?? 0);
  String get revenueRaw => Formatters.rawMoney(_summary?.revenue ?? 0);
  String get operatingCostsRaw =>
      Formatters.rawMoney(_summary?.operatingCosts ?? 0);
  String get receivedRaw => Formatters.rawMoney(_summary?.received ?? 0);
  String get paidOutRaw => Formatters.rawMoney(_summary?.paidOut ?? 0);
  String get receivable => Formatters.money(_summary?.totalReceivables ?? 0);
  String get payable => Formatters.money(_summary?.totalPayables ?? 0);
  int get receivableCount => _summary?.receivableCount ?? 0;
  int get payableCount => _summary?.payableCount ?? 0;

  List<AttentionItem> get attention {
    final pendingCheques = _summary?.pendingChequeCount ?? 0;
    final unbilled = _summary?.unbilledCount ?? 0;
    final expiries = _summary?.expiries ?? const [];

    final vehicleExpiries = expiries
        .where((e) => e.ownerType == 'vehicle')
        .toList();
    final driverExpiries = expiries
        .where((e) => e.ownerType == 'driver')
        .toList();

    return [
      AttentionItem(
        count: unbilled,
        title: unbilled == 1
            ? '1 completed job needs billing'
            : '$unbilled completed jobs need billing',
        subtitle: 'Prepare invoices before month end',
        onTap: openCompletedJobs,
      ),
      AttentionItem(
        count: pendingCheques,
        title: pendingCheques == 1
            ? '1 cheque awaiting clearance'
            : '$pendingCheques cheques awaiting clearance',
        subtitle: 'Balances update only after clearing',
        onTap: openPendingCheques,
      ),
      AttentionItem(
        count: vehicleExpiries.length,
        title: vehicleExpiries.length == 1
            ? '1 vehicle document expires soon'
            : '${vehicleExpiries.length} vehicle documents expire soon',
        subtitle: vehicleExpiries.isEmpty
            ? 'All registration and insurance details up to date'
            : vehicleExpiries
                  .map((row) => '${row.ownerName} ${row.kind}')
                  .take(2)
                  .join(' · '),
        onTap: openVehicleDocuments,
      ),
      AttentionItem(
        count: driverExpiries.length,
        title: driverExpiries.length == 1
            ? '1 driver document expires soon'
            : '${driverExpiries.length} driver documents expire soon',
        subtitle: driverExpiries.isEmpty
            ? 'All driver licences and identity cards are valid'
            : driverExpiries
                  .map((row) => '${row.ownerName} ${row.kind}')
                  .take(2)
                  .join(' · '),
        onTap: openDriverDocuments,
      ),
    ];
  }

  Future<void> init() => load();

  Future<void> refreshSummery() async {
    _repository.invalidateCache();
    await load();
  }

  Future<void> load({bool fresh = false}) async {
    if (isBusy) return;
    if (fresh) _repository.invalidateCache();

    setBusy(true);
    errorMessage = null;
    switch (await _repository.fetchSummary(_period)) {
      case Success(:final value):
        _summary = value;
      case Failure(:final failure):
        errorMessage = failure.message;
    }
    setBusy(false);
  }

  Future<void> selectPeriod() async {
    final response = await _bottomSheets
        .showCustomSheet<Period, PeriodSheetData>(
          variant: BottomSheetType.period,
          data: (selected: _period, resetTo: Period.thisMonth()),
          isScrollControlled: true,
        );
    final period = response?.data;
    if (period == null) return;
    _period = period;
    await load();
  }

  Future<void> newTrip() async {
    await _navigation.navigateTo(Routes.newTripView);
  }

  Future<void> paymentIn() => _record(PaymentDirection.incoming);
  Future<void> paymentOut() => _record(PaymentDirection.outgoing);
  Future<Payment?> _showPayment(PaymentDirection direction) async {
    final response = await _bottomSheets
        .showCustomSheet<Payment, PaymentFormData>(
          variant: BottomSheetType.paymentForm,
          data: PaymentFormData(direction: direction),
          isScrollControlled: true,
        );
    return response?.data;
  }

  Future<void> addExpense() async {
    if (busy(HomeBusy.addExpense)) return;
    final response = await _bottomSheets.showCustomSheet<Expense, dynamic>(
      variant: BottomSheetType.addExpense,
      isScrollControlled: true,
    );
    final expense = response?.data;
    if (expense == null) return;
    switch (await runBusyFuture(
      _moneyRepository.addExpense(expense),
      busyObject: HomeBusy.addExpense,
    )) {
      case Success():
        await load();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
  }

  Future<void> _record(PaymentDirection direction) async {
    if (busy(HomeBusy.recordPayment)) return;
    final payment = await _showPayment(direction);
    if (payment == null) return;
    switch (await runBusyFuture(
      _moneyRepository.recordPayment(payment),
      busyObject: HomeBusy.recordPayment,
    )) {
      case Success():
        await load();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
  }

  void openReceivables() {
    _shellService.setIndex(2); // Money tab
    _shellService.setMoneySegment(MoneySegment.invoices);
  }

  void openPayables() {
    _shellService.setIndex(2); // Money tab
    _shellService.setMoneySegment(MoneySegment.settlements);
  }

  void openCompletedJobs() {
    _shellService.setIndex(1); // Work tab
    _shellService.setWorkFilter(WorkStatus.completed);
  }

  void openPendingCheques() {
    _shellService.setIndex(2); // Money tab
    _shellService.setMoneySegment(MoneySegment.payments);
  }

  void openVehicleDocuments() {
    _navigation.navigateTo(Routes.vehiclesView);
  }

  void openDriverDocuments() {
    _navigation.navigateTo(Routes.driversView);
  }

  Future<void> seedDemoData() async {
    if (busy(HomeBusy.seedDemoData)) return;
    try {
      final message = await runBusyFuture(
        dev_seed.seedDemoData(),
        busyObject: HomeBusy.seedDemoData,
      );
      _snackbar.showSuccess(message);
      await load();
    } catch (error) {
      _snackbar.showError('Seed failed: $error');
    }
  }
}
