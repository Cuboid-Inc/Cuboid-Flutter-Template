import 'package:fleetgo/app/app.bottomsheets.dart';
import 'package:fleetgo/app/app.dialogs.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/agreement.dart';
import 'package:fleetgo/core/models/driver.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/models/route_rate.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/core/money.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/more/data/agreement_repository.dart';
import 'package:fleetgo/features/more/data/driver_repository.dart';
import 'package:fleetgo/features/more/data/route_rate_repository.dart';
import 'package:fleetgo/features/more/data/vehicle_repository.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/features/shell/shell_service.dart';
import 'package:fleetgo/features/work/data/work_repository.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum NewTripBusy { addCustomer, addRouteRate, saveWorkOrder }

class NewTripViewModel extends BaseViewModel {
  NewTripViewModel({
    WorkRepository? workRepository,
    PartiesRepository? partiesRepository,
    VehicleRepository? vehicleRepository,
    DriverRepository? driverRepository,
    AgreementRepository? agreementRepository,
    RouteRateRepository? routeRateRepository,
  }) : _workRepository = workRepository ?? locator<WorkRepository>(),
       _partiesRepository = partiesRepository ?? locator<PartiesRepository>(),
       _vehicleRepository = vehicleRepository ?? locator<VehicleRepository>(),
       _driverRepository = driverRepository ?? locator<DriverRepository>(),
       _agreementRepository =
           agreementRepository ?? locator<AgreementRepository>(),
       _routeRateRepository =
           routeRateRepository ?? locator<RouteRateRepository>() {
    rate.addListener(notifyListeners);
  }

  final WorkRepository _workRepository;
  final PartiesRepository _partiesRepository;
  final VehicleRepository _vehicleRepository;
  final DriverRepository _driverRepository;
  final AgreementRepository _agreementRepository;
  final RouteRateRepository _routeRateRepository;
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();
  final _bottomSheets = locator<BottomSheetService>();
  final _dialogs = locator<DialogService>();
  final _shellService = locator<ShellService>();

  final pickup = TextEditingController();
  final destination = TextEditingController();
  final rate = TextEditingController();
  int step = 1;
  String? customerId;
  String? agreementId;
  String? vehicleId;
  String? driverId;
  String? routeId;
  VehicleOwnership ownership = VehicleOwnership.owned;
  DateTime tripDate = DateTime.now();

  final Set<String> _extras = {};
  final Map<String, num> _customExtras = {};

  Party? selectedCustomer;
  Agreement? selectedAgreement;
  Vehicle? selectedVehicle;
  Driver? selectedDriver;
  RouteRate? selectedRoute;
  List<Agreement> matchingAgreements = const [];

  Agreement? get agreement =>
      selectedAgreement ??
      (matchingAgreements.length == 1 ? matchingAgreements.first : null);
  Vehicle? get vehicle => selectedVehicle;
  RouteRate? get route => selectedRoute;
  List<String> get extras => _extras.toList();

  List<String> get availableExtras => _customExtras.keys.toList();

  List<String> get unselectedExtras =>
      availableExtras.where((e) => !_extras.contains(e)).toList();

  num get total => roundMoney(
    (Formatters.parseMoney(rate.text) ?? 0) +
        _extras.fold<num>(
          0,
          (sum, name) => roundMoney(sum + (_customExtras[name] ?? 0)),
        ),
  );

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

  Future<Result<PaginatedResult<Vehicle>>> fetchVehiclesPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
  }) => _vehicleRepository.fetchVehiclesPage(
    pageNumber: pageNumber,
    pageSize: pageSize,
    search: search,
  );

  Future<Result<PaginatedResult<Driver>>> fetchDriversPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
  }) => _driverRepository.fetchDriversPage(
    pageNumber: pageNumber,
    pageSize: pageSize,
    search: search,
  );

  Future<Result<PaginatedResult<RouteRate>>> fetchRouteRatesPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
  }) => _routeRateRepository.fetchRouteRatesPage(
    pageNumber: pageNumber,
    pageSize: pageSize,
    search: search,
  );

  Future<void> init() async {}

  Future<void> selectCustomer(Party? party) async {
    selectedCustomer = party;
    customerId = party?.id;
    matchingAgreements = const [];
    selectedAgreement = null;
    agreementId = null;
    notifyListeners();

    if (party == null) return;
    final selectedId = party.id;
    switch (await _agreementRepository.fetchAgreementsPage(
      customerId: selectedId,
      rateModel: RateModel.perTrip,
      pageNumber: 1,
      pageSize: 50,
    )) {
      case Success(:final value):
        if (selectedCustomer?.id != selectedId) return;
        matchingAgreements = value.items;
        if (matchingAgreements.length == 1) {
          selectedAgreement = matchingAgreements.first;
          agreementId = selectedAgreement!.id;
        }
      case Failure(:final failure):
        if (selectedCustomer?.id != selectedId) return;
        _snackbar.showError(failure.message);
    }
    notifyListeners();
  }

  void selectAgreement(Agreement? value) {
    selectedAgreement = value;
    agreementId = value?.id;
    notifyListeners();
  }

  void selectVehicle(Vehicle? value) {
    selectedVehicle = value;
    vehicleId = value?.id;
    ownership = value?.ownership ?? VehicleOwnership.owned;
    notifyListeners();
  }

  void selectDriver(Driver? value) {
    selectedDriver = value;
    driverId = value?.id;
    notifyListeners();
  }

  void selectOwnership(VehicleOwnership value) {
    ownership = value;
    notifyListeners();
  }

  void selectExtras(List<String> values) {
    _extras
      ..clear()
      ..addAll(values);
    notifyListeners();
  }

  void setTripDate(DateTime val) {
    tripDate = val;
    notifyListeners();
  }

  void selectRoute(RouteRate value) {
    selectedRoute = value;
    routeId = value.id;
    pickup.text = value.pickup;
    destination.text = value.destination;
    rate.text = Formatters.rawMoney(value.rate);
    _customExtras
      ..clear()
      ..addAll(value.defaultExtras);
    _extras
      ..clear()
      ..addAll(value.defaultExtras.keys);
    notifyListeners();
  }

  Future<void> addCustomer() async {
    if (busy(NewTripBusy.addCustomer)) return;
    await runBusyFuture(() async {
      final response = await _bottomSheets.showCustomSheet<Party, Object?>(
        variant: BottomSheetType.partyForm,
        isScrollControlled: true,
      );
      final party = response?.data;
      if (party == null) return;

      switch (await _partiesRepository.create(party)) {
        case Success(:final value):
          await selectCustomer(value);
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: NewTripBusy.addCustomer);
  }

  Future<void> addRouteRate() async {
    if (busy(NewTripBusy.addRouteRate)) return;
    await runBusyFuture(() async {
      final response = await _bottomSheets.showCustomSheet<RouteRate, dynamic>(
        variant: BottomSheetType.routeRateForm,
        isScrollControlled: true,
      );
      final routeRate = response?.data;
      if (routeRate == null) return;

      switch (await _routeRateRepository.addRouteRate(routeRate)) {
        case Success(:final value):
          selectRoute(value);
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: NewTripBusy.addRouteRate);
  }

  bool addCustomExtra(String name, num rate) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;
    if (_customExtras.containsKey(cleanName)) {
      return false;
    }
    _customExtras[cleanName] = rate;
    _extras.add(cleanName);
    notifyListeners();
    return true;
  }

  void updateExtraRate(String name, num rate) {
    _customExtras[name] = rate;
    notifyListeners();
  }

  /// Opens the Add Custom Extra dialog via [DialogService].
  Future<void> openAddCustomExtraDialog() async {
    final response = await _dialogs.showCustomDialog(
      variant: DialogType.addEditExtra,
    );
    if (response?.confirmed != true) return;
    final data = response!.data as Map<String, dynamic>;
    final name = data['name'] as String;
    final amount = data['amount'] as num;
    addCustomExtra(name, amount);
  }

  /// Opens the Edit Extra Rate dialog via [DialogService].
  Future<void> openEditExtraRateDialog(String extraName) async {
    final current = extraRate(extraName);
    final response = await _dialogs.showCustomDialog(
      variant: DialogType.addEditExtra,
      data: {'name': extraName, 'amount': current},
    );
    if (response?.confirmed != true) return;
    final data = response!.data as Map<String, dynamic>;
    final newAmount = data['amount'] as num;
    updateExtraRate(extraName, newAmount);
  }

  num extraRate(String name) => _customExtras[name] ?? 0;

  Future<void> cancel() async {
    final result = await _dialogs.showCustomDialog(
      variant: DialogType.confirm,
      title: "Cancel Trip",
      description: 'Are you sure you want to cancel this trip?',
    );
    if (result != null && result.confirmed) {
      _navigation.back();
    }
  }

  void back() {
    if (step > 1) {
      step--;
      notifyListeners();
    } else {
      _navigation.back();
    }
  }

  Future<void> next() async {
    if (busy(NewTripBusy.saveWorkOrder)) return;
    if (step < 3) {
      if (step == 1) {
        if (customerId == null) {
          _snackbar.showWarning('Please select a customer');
          return;
        }
        if (matchingAgreements.length > 1 && agreementId == null) {
          _snackbar.showWarning('Please select an agreement');
          return;
        }
        if (pickup.text.trim().isEmpty) {
          _snackbar.showWarning('Please specify the pickup place');
          return;
        }
        if (destination.text.trim().isEmpty) {
          _snackbar.showWarning('Please specify the destination');
          return;
        }
      } else if (step == 2) {
        if (vehicleId == null) {
          _snackbar.showWarning('Please select a vehicle');
          return;
        }
        if (driverId == null) {
          _snackbar.showWarning('Please select a driver');
          return;
        }
      }
      step++;
      notifyListeners();
      return;
    }

    await runBusyFuture(
      _saveWorkOrder(),
      busyObject: NewTripBusy.saveWorkOrder,
    );
  }

  Future<void> _saveWorkOrder() async {
    try {
      final selectedVehicle = vehicle;
      final selectedDriverValue = selectedDriver;
      final agreementValue = agreement;
      final net = total;

      if (selectedVehicle == null) {
        _snackbar.showWarning('Please select a vehicle');
        return;
      }
      if (selectedDriverValue == null) {
        _snackbar.showWarning('Please select a driver');
        return;
      }
      if (net <= 0) {
        _snackbar.showWarning('Trip rate must be greater than zero');
        return;
      }

      // Ask to save custom route if routeId is null
      if (routeId == null) {
        final shouldSave = await _dialogs.showCustomDialog(
          title: 'Save New Route?',
          description:
              'Would you like to save this new route and its extra charges for future use?',
        );

        if (shouldSave != null && shouldSave.confirmed) {
          final newRoute = RouteRate(
            id: '',
            appliesTo: 'All customers',
            pickup: pickup.text.trim(),
            destination: destination.text.trim(),
            vehicleClass: selectedVehicle.vehicleClass,
            rate: Formatters.parseMoney(rate.text) ?? 0,
            defaultExtras: Map<String, num>.from(_customExtras),
          );
          switch (await _routeRateRepository.addRouteRate(newRoute)) {
            case Success(:final value):
              routeId = value.id;
            case Failure(:final failure):
              _snackbar.showError(failure.message);
          }
        }
      }

      final tripRate = Formatters.parseMoney(rate.text) ?? 0;
      switch (await _workRepository.create(
        WorkOrder(
          id: '',
          number: '',
          customerId: customerId!,
          agreementId: agreementValue?.id,
          date: tripDate,
          pickup: pickup.text.trim(),
          destination: destination.text.trim(),
          allocations: [
            VehicleAllocation(
              vehicleId: selectedVehicle.id,
              driverId: selectedDriverValue.id,
              source: ownership == VehicleOwnership.external
                  ? VehicleSource.supplier
                  : VehicleSource.owned,
              supplierId: selectedVehicle.supplierId,
              supplierPayable: 0,
            ),
          ],
          chargeLines: [
            ChargeLine(name: 'Transport service', unitPrice: tripRate),
            for (final name in _extras)
              ChargeLine(name: name, unitPrice: _customExtras[name] ?? 0),
          ],
        ),
      )) {
        case Success(:final value):
          final label = value.number.isNotEmpty
              ? '${value.number} created'
              : 'Work order created';
          _shellService.setIndex(1); // Work tab
          _shellService.setWorkFilter(WorkStatus.planned);
          _navigation.back();
          _snackbar.showSuccess(label);

        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    } catch (_) {
      _snackbar.showError('Unable to save work order. Please try again.');
    }
  }

  @override
  void dispose() {
    rate.removeListener(notifyListeners);
    pickup.dispose();
    destination.dispose();
    rate.dispose();
    super.dispose();
  }
}
