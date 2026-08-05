import 'package:cuboid_flutter_template/app/app.bottomsheets.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/period.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/money.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/money/data/money_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:cuboid_flutter_template/ui/bottom_sheets/period/period_sheet_model.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum PrepareMonthBusy { issueInvoice }

class PrepareMonthViewModel extends BaseViewModel {
  PrepareMonthViewModel({
    this.customerId,
    MoneyRepository? moneyRepository,
    PartiesRepository? partiesRepository,
  }) : _moneyRepository = moneyRepository ?? locator<MoneyRepository>(),
       _partiesRepository = partiesRepository ?? locator<PartiesRepository>();

  final MoneyRepository _moneyRepository;
  final PartiesRepository _partiesRepository;
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();
  final _bottomSheets = locator<BottomSheetService>();
  final Set<String> _selected = {};
  String? customerId;
  Period period = Period.thisMonth();
  Party? selectedCustomer;
  List<WorkOrder> _allWorks = const [];

  List<WorkOrder> get works => _allWorks
      .where(
        (work) => work.customerId == customerId && period.contains(work.date),
      )
      .toList();
  num get net => works
      .where((work) => _selected.contains(work.id))
      .fold<num>(0, (sum, work) => roundMoney(sum + work.net));
  num get vat => vatAmount(net, 5);
  bool get canIssue =>
      selectedCustomer != null && _selected.isNotEmpty && net > 0;

  Future<void> init() async {
    setBusy(true);
    if (customerId != null) {
      switch (await _partiesRepository.fetchById(customerId!)) {
        case Success(:final value):
          selectedCustomer = value;
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }
    switch (await _moneyRepository.fetchUnbilledWork()) {
      case Success(:final value):
        _allWorks = [for (final row in value) row.workOrder];
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    _selectAllEligible();
    setBusy(false);
  }

  Future<Result<PaginatedResult<Party>>> fetchCustomersPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
  }) => _partiesRepository.fetchPage(
    type: PartyType.customer,
    pageNumber: pageNumber,
    pageSize: pageSize,
    search: search,
  );

  void selectCustomer(Party? party) {
    selectedCustomer = party;
    customerId = party?.id;
    _selectAllEligible();
    notifyListeners();
  }

  Future<void> choosePeriod() async {
    final response = await _bottomSheets
        .showCustomSheet<Period, PeriodSheetData>(
          variant: BottomSheetType.period,
          data: (selected: period, resetTo: Period.thisMonth()),
          isScrollControlled: true,
        );
    final selected = response?.data;
    if (selected == null) return;
    period = selected;
    _selectAllEligible();
    notifyListeners();
  }

  void _selectAllEligible() {
    _selected
      ..clear()
      ..addAll(works.map((work) => work.id));
  }

  void toggleWork(String id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  bool isSelected(String id) => _selected.contains(id);

  Future<void> issue() async {
    if (busy(PrepareMonthBusy.issueInvoice)) return;
    if (!canIssue) return;
    final party = selectedCustomer!;
    await runBusyFuture(() async {
      final lines = [
        for (final work in works.where((item) => _selected.contains(item.id)))
          for (final line in work.chargeLines)
            InvoiceLine(
              name: '${work.number} · ${line.name}',
              quantity: line.quantity,
              unitPrice: line.unitPrice,
              vatRate: line.vatRate,
            ),
      ];
      switch (await _moneyRepository.issueInvoice(
        Invoice(
          id: 'invoice-${DateTime.now().microsecondsSinceEpoch}',
          number: '',
          buyerId: party.id,
          buyerName: party.name,
          buyerAddress: party.address,
          buyerTrn: party.trn,
          buyerContact: party.contactPerson,
          paymentTerms: party.paymentTerms.label,
          issueDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 30)),
          lines: lines,
          linkedWorkOrderIds: _selected.toList(),
          status: InvoiceStatus.draft,
        ),
      )) {
        case Success(:final value):
          _snackbar.showSuccess('${value.number} issued');
          _navigation.back();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: PrepareMonthBusy.issueInvoice);
  }
}
