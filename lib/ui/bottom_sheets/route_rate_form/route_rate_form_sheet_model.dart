import 'package:cuboid_flutter_template/app/app.dialogs.dart';
import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/route_rate.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class RouteRateFormSheetModel extends BaseViewModel {
  RouteRateFormSheetModel({required this.completer, required this.request})
    : _partiesRepository = locator<PartiesRepository>(),
      _dialogs = locator<DialogService>() {
    if (request.data is RouteRate) {
      final initial = request.data as RouteRate;
      pickupController.text = initial.pickup;
      destinationController.text = initial.destination;
      rateAEDController.text = Formatters.rawMoney(initial.rate);
      appliesTo = initial.appliesTo;
      vehicleClass = initial.vehicleClass;

      extras = initial.defaultExtras.entries
          .map((e) => MapEntry(e.key, e.value.toDouble()))
          .toList();
      for (final entry in extras) {
        extraKeyControllers.add(TextEditingController(text: entry.key));
        extraValControllers.add(
          TextEditingController(text: Formatters.rawMoney(entry.value)),
        );
      }
    }
  }

  final Function(SheetResponse response) completer;
  final SheetRequest request;
  final PartiesRepository _partiesRepository;
  final DialogService _dialogs;

  final pickupController = TextEditingController();
  final destinationController = TextEditingController();
  final rateAEDController = TextEditingController(text: '0.00');
  final formKey = GlobalKey<FormState>();

  String appliesTo = 'All customers';
  VehicleClass vehicleClass = VehicleClass.threeTon;

  List<Party> customers = [];
  String? loadErrorMessage;

  String? get errorMessage => loadErrorMessage;

  List<MapEntry<String, num>> extras = [];
  final List<TextEditingController> extraKeyControllers = [];
  final List<TextEditingController> extraValControllers = [];

  bool get isEditing => request.data is RouteRate;

  Future<void> init() async {
    setBusy(true);
    switch (await _partiesRepository.partiesForDirection(
      PaymentDirection.incoming,
    )) {
      case Success(:final value):
        customers = value;
      case Failure(:final failure):
        loadErrorMessage = failure.message;
    }
    setBusy(false);
  }

  void selectAppliesTo(String value) {
    appliesTo = value;
    notifyListeners();
  }

  void selectVehicleClass(VehicleClass? val) {
    if (val != null) {
      vehicleClass = val;
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

  void submit() {
    final pickup = pickupController.text.trim();
    final destination = destinationController.text.trim();
    final rate = Formatters.parseMoney(rateAEDController.text);
    if (pickup.isEmpty || destination.isEmpty || rate == null || rate <= 0) {
      return;
    }

    final initialRoute = request.data is RouteRate
        ? request.data as RouteRate
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
      SheetResponse<RouteRate>(
        confirmed: true,
        data: RouteRate(
          id: initialRoute?.id ?? '',
          appliesTo: appliesTo,
          pickup: pickup,
          destination: destination,
          vehicleClass: vehicleClass,
          rate: rate,
          defaultExtras: defaultExtras,
        ),
      ),
    );
  }

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
    pickupController.dispose();
    destinationController.dispose();
    rateAEDController.dispose();
    for (var c in extraKeyControllers) {
      c.dispose();
    }
    for (var c in extraValControllers) {
      c.dispose();
    }
    super.dispose();
  }
}
