import 'package:fleetgo/app/app.dialogs.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/agreement.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/more/data/vehicle_repository.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class AgreementFormSheetModel extends BaseViewModel {
  AgreementFormSheetModel({required this.completer, required this.request})
    : _partiesRepository = locator<PartiesRepository>(),
      _vehicleRepository = locator<VehicleRepository>(),
      _dialogs = locator<DialogService>() {
    if (request.data is Agreement) {
      final initialAgreement = request.data as Agreement;
      nameController.text = initialAgreement.name;
      baseRateAEDController.text = _formatToAED(initialAgreement.baseRate);
      vatRateController.text = initialAgreement.vatRate.toString();
      dutyDaysController.text = initialAgreement.dutyDays.toString();
      includedHoursController.text = initialAgreement.includedHours.toString();
      overtimeRateController.text = _formatToAED(initialAgreement.overtimeRate);
      extraDayRateController.text = _formatToAED(initialAgreement.extraDayRate);
      extraTripRateController.text = _formatToAED(
        initialAgreement.extraTripRate,
      );
      notesController.text = initialAgreement.notes ?? '';

      extras = initialAgreement.defaultExtras.entries
          .map((e) => MapEntry(e.key, e.value.toDouble()))
          .toList();
      for (final entry in extras) {
        extraKeyControllers.add(TextEditingController(text: entry.key));
        extraValControllers.add(
          TextEditingController(text: Formatters.rawMoney(entry.value)),
        );
      }

      rateModel = initialAgreement.rateModel;
      customerId = initialAgreement.customerId;
      defaultVehicleId = initialAgreement.defaultVehicleId;
      startDate = initialAgreement.startDate;
      endDate = initialAgreement.endDate;
      paymentTerms = initialAgreement.paymentTerms;
    }
  }

  final Function(SheetResponse response) completer;
  final SheetRequest request;
  final PartiesRepository _partiesRepository;
  final VehicleRepository _vehicleRepository;
  final DialogService _dialogs;

  final nameController = TextEditingController();
  final baseRateAEDController = TextEditingController(text: '0.00');
  final vatRateController = TextEditingController(text: '5');
  final dutyDaysController = TextEditingController(text: '0');
  final includedHoursController = TextEditingController(text: '0');
  final overtimeRateController = TextEditingController(text: '0.00');
  final extraDayRateController = TextEditingController(text: '0.00');
  final extraTripRateController = TextEditingController(text: '0.00');
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  RateModel rateModel = RateModel.perTrip;
  String? customerId;
  String? defaultVehicleId;
  Party? selectedCustomer;
  Vehicle? selectedVehicle;
  PaymentTerms paymentTerms = PaymentTerms.onReceipt;
  DateTime? startDate;
  DateTime? endDate;

  String? loadErrorMessage;

  String? get errorMessage => loadErrorMessage;

  List<MapEntry<String, num>> extras = [];
  final List<TextEditingController> extraKeyControllers = [];
  final List<TextEditingController> extraValControllers = [];

  bool get isEditing => request.data is Agreement;

  Future<void> init() async {
    if (!isEditing || defaultVehicleId == null) return;
    setBusy(true);
    switch (await _vehicleRepository.fetchById(defaultVehicleId!)) {
      case Success(:final value):
        selectedVehicle = value;
      case Failure(:final failure):
        loadErrorMessage = failure.message;
    }
    setBusy(false);
  }

  void selectRateModel(RateModel? val) {
    if (val != null) {
      rateModel = val;
      notifyListeners();
    }
  }

  void selectCustomer(Party? val) {
    selectedCustomer = val;
    customerId = val?.id;
    notifyListeners();
  }

  void selectVehicle(Vehicle? val) {
    selectedVehicle = val;
    defaultVehicleId = val?.id;
    notifyListeners();
  }

  Future<Result<PaginatedResult<Party>>> fetchCustomersPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
  }) => _partiesRepository.fetchPage(
    pageNumber: pageNumber,
    pageSize: pageSize,
    type: PartyType.customer,
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

  void selectPaymentTerms(PaymentTerms? val) {
    if (val != null) {
      paymentTerms = val;
      notifyListeners();
    }
  }

  /// Opens the Add Extra dialog via the Stacked [DialogService].
  Future<void> openAddExtraDialog() async {
    final response = await _dialogs.showCustomDialog(
      variant: DialogType.addEditExtra,
      // No data = add mode (empty fields).
    );
    if (response?.confirmed != true) return;
    final data = response!.data as Map<String, dynamic>;
    final name = data['name'] as String;
    final amount = data['amount'] as num;
    // Prevent duplicate names.
    if (extras.any((e) => e.key.toLowerCase() == name.toLowerCase())) return;
    extras.add(MapEntry(name, amount));
    extraKeyControllers.add(TextEditingController(text: name));
    extraValControllers.add(
      TextEditingController(text: Formatters.rawMoney(amount)),
    );
    notifyListeners();
  }

  /// Opens the Edit Extra dialog via the Stacked [DialogService].
  Future<void> openEditExtraDialog(int index) async {
    final entry = extras[index];
    final response = await _dialogs.showCustomDialog(
      variant: DialogType.addEditExtra,
      data: {'name': entry.key, 'amount': entry.value},
    );
    if (response?.confirmed != true) return;
    final data = response!.data as Map<String, dynamic>;
    final newAmount = data['amount'] as num;
    extras[index] = MapEntry(entry.key, newAmount);
    extraValControllers[index].text = Formatters.rawMoney(newAmount);
    notifyListeners();
  }

  void removeExtra(int index) {
    extras.removeAt(index);
    extraKeyControllers[index].dispose();
    extraValControllers[index].dispose();
    extraKeyControllers.removeAt(index);
    extraValControllers.removeAt(index);
    notifyListeners();
  }

  Future<void> pickDate(BuildContext context, int type) async {
    final initialDate = switch (type) {
      1 => startDate ?? DateTime.now(),
      2 => endDate ?? DateTime.now(),
      _ => DateTime.now(),
    };

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      if (type == 1) startDate = picked;
      if (type == 2) endDate = picked;
      notifyListeners();
    }
  }

  void submit() {
    final name = nameController.text.trim();
    final baseRate = _parseAEDTo(baseRateAEDController.text);
    final overtimeRate = _parseAEDTo(overtimeRateController.text);
    final extraDayRate = _parseAEDTo(extraDayRateController.text);
    final extraTripRate = _parseAEDTo(extraTripRateController.text);
    final dutyDays = int.tryParse(dutyDaysController.text.trim());
    final includedHours = int.tryParse(includedHoursController.text.trim());
    final vatRate = int.tryParse(vatRateController.text.trim());
    if (name.isEmpty ||
        customerId == null ||
        baseRate == null ||
        overtimeRate == null ||
        extraDayRate == null ||
        extraTripRate == null ||
        dutyDays == null ||
        dutyDays < 0 ||
        dutyDays > 31 ||
        includedHours == null ||
        includedHours < 0 ||
        includedHours > 744 ||
        vatRate == null ||
        vatRate < 0 ||
        vatRate > 100 ||
        baseRate < 0 ||
        overtimeRate < 0 ||
        extraDayRate < 0 ||
        extraTripRate < 0) {
      return;
    }

    final initialAgreement = request.data is Agreement
        ? request.data as Agreement
        : null;

    final Map<String, num> defaultExtras = {};
    for (var i = 0; i < extras.length; i++) {
      final key = extraKeyControllers[i].text.trim();
      final valStr = extraValControllers[i].text.trim();
      final value = Formatters.parseMoney(valStr);
      if (key.isEmpty || value == null || value < 0) return;
      defaultExtras[key] = value;
    }

    completer(
      SheetResponse<Agreement>(
        confirmed: true,
        data: Agreement(
          id: initialAgreement?.id ?? '',
          reference: initialAgreement?.reference ?? '',
          name: name,
          customerId: customerId!,
          rateModel: rateModel,
          startDate: startDate,
          endDate: endDate,
          baseRate: baseRate,
          dutyDays: dutyDays,
          includedHours: includedHours,
          overtimeRate: overtimeRate,
          extraDayRate: extraDayRate,
          extraTripRate: extraTripRate,
          vatRate: vatRate,
          defaultVehicleId: defaultVehicleId,
          paymentTerms: paymentTerms,
          defaultExtras: defaultExtras,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        ),
      ),
    );
  }

  String _formatToAED(num amount) {
    return Formatters.rawMoney(amount);
  }

  num? _parseAEDTo(String value) => Formatters.parseMoney(value);

  String? validateExtras() {
    for (var i = 0; i < extras.length; i++) {
      if (extraKeyControllers[i].text.trim().isEmpty) {
        return 'Extra name is required';
      }
      final value = Formatters.parseMoney(extraValControllers[i].text);
      if (value == null || value < 0) {
        return 'Extra rates must be valid amounts of 0 or more';
      }
    }
    return null;
  }

  @override
  void dispose() {
    nameController.dispose();
    baseRateAEDController.dispose();
    vatRateController.dispose();
    dutyDaysController.dispose();
    includedHoursController.dispose();
    overtimeRateController.dispose();
    extraDayRateController.dispose();
    extraTripRateController.dispose();
    notesController.dispose();
    for (var c in extraKeyControllers) {
      c.dispose();
    }
    for (var c in extraValControllers) {
      c.dispose();
    }
    super.dispose();
  }
}
