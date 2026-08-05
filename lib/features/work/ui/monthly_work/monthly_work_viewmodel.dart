import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/money.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/more/data/agreement_repository.dart';
import 'package:cuboid_flutter_template/features/shell/shell_service.dart';
import 'package:cuboid_flutter_template/features/work/data/work_repository.dart';
import 'package:cuboid_flutter_template/ui/common/snackbar_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum MonthlyWorkBusy { saveWorkOrder }

class MonthlyWorkCharge {
  MonthlyWorkCharge({
    required this.type,
    required this.name,
    required this.quantity,
    required this.rate,
    this.isBaseLine = false,
  });

  final MonthlyExtraType type;
  final String name;
  final int quantity;
  final num rate;
  final bool isBaseLine;

  num get lineTotal => roundMoney(quantity * rate);
}

class MonthlyWorkViewModel extends BaseViewModel {
  MonthlyWorkViewModel({
    AgreementRepository? agreementRepository,
    WorkRepository? workRepository,
  }) : _agreementRepository =
           agreementRepository ?? locator<AgreementRepository>(),
       _workRepository = workRepository ?? locator<WorkRepository>();

  final AgreementRepository _agreementRepository;
  final WorkRepository _workRepository;
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();
  final _shellService = locator<ShellService>();

  int step = 1;
  Agreement? selectedAgreement;
  DateTime serviceDate = DateTime.now();
  List<MonthlyWorkCharge> charges = [];

  Agreement? get agreement => selectedAgreement;

  num get total => roundMoney(
    charges.fold<num>(0, (sum, charge) => roundMoney(sum + charge.lineTotal)),
  );

  Future<void> init() async {}

  Future<Result<PaginatedResult<Agreement>>> fetchMonthlyAgreementsPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
  }) => _agreementRepository.fetchAgreementsPage(
    rateModel: RateModel.monthly,
    pageNumber: pageNumber,
    pageSize: pageSize,
    search: search,
  );

  void selectAgreement(Agreement? value) {
    selectedAgreement = value;
    final selected = value;
    charges = selected == null
        ? []
        : [
            MonthlyWorkCharge(
              type: MonthlyExtraType.custom,
              name: 'Monthly hire',
              quantity: 1,
              rate: selected.baseRate,
              isBaseLine: true,
            ),
          ];
    notifyListeners();
  }

  void setServiceDate(DateTime value) {
    serviceDate = value;
    notifyListeners();
  }

  num defaultRateFor(MonthlyExtraType type, {String? customName}) {
    final selected = agreement;
    if (selected == null) return 0;
    return switch (type) {
      MonthlyExtraType.overtime => selected.overtimeRate,
      MonthlyExtraType.extraDay => selected.extraDayRate,
      MonthlyExtraType.extraTrip => selected.extraTripRate,
      _ =>
        selected.defaultExtras[type == MonthlyExtraType.custom
                ? (customName ?? '')
                : type.label] ??
            0,
    };
  }

  void addCharge(
    MonthlyExtraType type, {
    required int quantity,
    required num rate,
    String? customName,
  }) {
    final name = type == MonthlyExtraType.custom
        ? (customName ?? '').trim()
        : type.label;
    if (name.isEmpty || quantity < 1 || rate < 0) return;
    charges = [
      ...charges,
      MonthlyWorkCharge(
        type: type,
        name: name,
        quantity: quantity,
        rate: roundMoney(rate),
      ),
    ];
    notifyListeners();
  }

  void removeCharge(int index) {
    charges = [...charges]..removeAt(index);
    notifyListeners();
  }

  Future<void> next() async {
    if (busy(MonthlyWorkBusy.saveWorkOrder)) return;
    if (step == 1) {
      if (selectedAgreement == null) {
        _snackbar.showWarning('Please select an agreement');
        return;
      }
      step = 2;
      notifyListeners();
      return;
    }
    if (step == 2) {
      if (charges.isEmpty) {
        _snackbar.showWarning('Add at least one charge');
        return;
      }
      step = 3;
      notifyListeners();
      return;
    }
    await runBusyFuture(_save(), busyObject: MonthlyWorkBusy.saveWorkOrder);
  }

  void back() {
    if (step > 1) {
      step--;
      notifyListeners();
    } else {
      _navigation.back();
    }
  }

  Future<void> _save() async {
    final selected = selectedAgreement;
    if (selected == null || charges.isEmpty) return;
    switch (await _workRepository.create(
      WorkOrder(
        id: '',
        number: '',
        customerId: selected.customerId,
        agreementId: selected.id,
        date: serviceDate,
        pickup: 'Monthly hire',
        destination: selected.name,
        workType: WorkType.monthlyExtra,
        status: WorkStatus.completed,
        allocations: [
          if (selected.defaultVehicleId != null)
            VehicleAllocation(vehicleId: selected.defaultVehicleId!),
        ],
        chargeLines: [
          for (final charge in charges)
            ChargeLine(
              name: charge.name,
              quantity: charge.quantity,
              unitPrice: charge.rate,
            ),
        ],
      ),
    )) {
      case Success(:final value):
        _shellService.setIndex(1);
        _shellService.setWorkFilter(WorkStatus.completed);
        _navigation.back();
        _snackbar.showSuccess(
          value.number.isNotEmpty
              ? '${value.number} created'
              : 'Work order created',
        );
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
  }
}
