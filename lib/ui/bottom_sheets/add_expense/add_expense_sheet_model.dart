import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/driver.dart';
import 'package:fleetgo/core/models/expense.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/more/data/driver_repository.dart';
import 'package:fleetgo/features/more/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class AddExpenseSheetModel extends BaseViewModel {
  AddExpenseSheetModel({required this.completer})
    : _vehicleRepository = locator<VehicleRepository>(),
      _driverRepository = locator<DriverRepository>();

  final Function(SheetResponse response) completer;
  final amountController = TextEditingController();
  final payeeController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final VehicleRepository _vehicleRepository;
  final DriverRepository _driverRepository;

  List<Vehicle> vehicles = const [];
  List<Driver> drivers = const [];

  ExpenseCategory category = ExpenseCategory.driverPay;
  String? vehicleId;
  String? driverId;

  String vehicleSearchQuery = '';
  String driverSearchQuery = '';
  String? loadErrorMessage;

  String? get errorMessage => loadErrorMessage;

  Future<void> init() async {
    setBusy(true);

    switch (await _vehicleRepository.fetchVehicles()) {
      case Success(:final value):
        vehicles = value.where((vehicle) => !vehicle.isExternal).toList();
      case Failure(:final failure):
        vehicles = const [];
        loadErrorMessage = failure.message;
    }

    switch (await _driverRepository.fetchDrivers()) {
      case Success(:final value):
        drivers = value;
      case Failure(:final failure):
        drivers = const [];
        loadErrorMessage = failure.message;
    }

    setBusy(false);
  }

  List<ExpenseCategory> get availableCategories =>
      ExpenseCategory.values.toList();

  bool get isVehicleExpense =>
      category == ExpenseCategory.fuel ||
      category == ExpenseCategory.maintenance ||
      category == ExpenseCategory.toll ||
      category == ExpenseCategory.parking ||
      category == ExpenseCategory.gatePass ||
      category == ExpenseCategory.vehicleRent;

  bool get isDriverExpense => category == ExpenseCategory.driverPay;

  List<Vehicle> get filteredVehicles {
    if (vehicleSearchQuery.trim().isEmpty) return vehicles;
    final query = vehicleSearchQuery.toLowerCase();
    return vehicles.where((v) {
      return (v.plateNumber).toLowerCase().contains(query) ||
          v.label.toLowerCase().contains(query);
    }).toList();
  }

  List<Driver> get filteredDrivers {
    if (driverSearchQuery.trim().isEmpty) return drivers;
    final query = driverSearchQuery.toLowerCase();
    return drivers.where((d) {
      return d.name.toLowerCase().contains(query);
    }).toList();
  }

  void selectCategory(List<ExpenseCategory> values) {
    category = values.first;
    vehicleId = null;
    driverId = null;
    vehicleSearchQuery = '';
    driverSearchQuery = '';
    payeeController.clear();
    notifyListeners();
  }

  void selectVehicle(Vehicle vehicle) {
    vehicleId = vehicle.id;
    vehicleSearchQuery = '';
    notifyListeners();
  }

  void clearVehicle() {
    vehicleId = null;
    vehicleSearchQuery = '';
    notifyListeners();
  }

  void selectDriver(Driver driver) {
    driverId = driver.id;
    driverSearchQuery = '';
    payeeController.text = driver.name;
    notifyListeners();
  }

  void clearDriver() {
    driverId = null;
    driverSearchQuery = '';
    payeeController.clear();
    notifyListeners();
  }

  void setVehicleSearchQuery(String val) {
    vehicleSearchQuery = val;
    notifyListeners();
  }

  void setDriverSearchQuery(String val) {
    driverSearchQuery = val;
    notifyListeners();
  }

  void submit() {
    final net = Formatters.parseMoney(amountController.text);
    final payee = payeeController.text.trim();
    if (net == null ||
        net <= 0 ||
        payee.isEmpty ||
        (isVehicleExpense && vehicleId == null) ||
        (isDriverExpense && driverId == null)) {
      return;
    }

    completer(
      SheetResponse<Expense>(
        confirmed: true,
        data: Expense(
          id: '',
          date: DateTime.now(),
          category: category,
          payee: payee,
          net: net,
          vehicleId: isVehicleExpense ? vehicleId : null,
          driverId: isDriverExpense ? driverId : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    payeeController.dispose();
    super.dispose();
  }
}
