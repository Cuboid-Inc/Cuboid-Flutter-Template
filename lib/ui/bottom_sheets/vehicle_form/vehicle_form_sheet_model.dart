import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/paginated_result.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class VehicleFormSheetModel extends BaseViewModel {
  VehicleFormSheetModel({required this.completer, required this.request})
    : _partiesRepository = locator<PartiesRepository>() {
    if (request.data is Vehicle) {
      final initialVehicle = request.data as Vehicle;
      plateNumberController.text = initialVehicle.plateNumber;
      labelController.text = initialVehicle.label;
      makeController.text = initialVehicle.make ?? '';
      modelController.text = initialVehicle.model ?? '';
      yearController.text = initialVehicle.year?.toString() ?? '';
      notesController.text = initialVehicle.notes ?? '';
      ownership = initialVehicle.ownership;
      vehicleClass = initialVehicle.vehicleClass;
      registrationExpiry = initialVehicle.registrationExpiry;
      insuranceExpiry = initialVehicle.insuranceExpiry;
      inspectionExpiry = initialVehicle.inspectionExpiry;
    }
  }

  final Function(SheetResponse response) completer;
  final SheetRequest request;
  final PartiesRepository _partiesRepository;

  final plateNumberController = TextEditingController();
  final labelController = TextEditingController();
  final makeController = TextEditingController();
  final modelController = TextEditingController();
  final yearController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  VehicleOwnership ownership = VehicleOwnership.owned;
  Party? selectedSupplier;
  VehicleClass vehicleClass = VehicleClass.threeTon;
  DateTime? registrationExpiry;
  DateTime? insuranceExpiry;
  DateTime? inspectionExpiry;

  String? loadErrorMessage;

  String? get errorMessage => loadErrorMessage;

  bool get isEditing => request.data is Vehicle;

  Future<void> init() async {
    final initialVehicle = request.data is Vehicle
        ? request.data as Vehicle
        : null;
    final supplierId = initialVehicle?.supplierId;
    if (!isEditing ||
        ownership != VehicleOwnership.external ||
        supplierId == null) {
      return;
    }
    setBusy(true);
    switch (await _partiesRepository.fetchById(supplierId)) {
      case Success(:final value):
        selectedSupplier = value;
      case Failure(:final failure):
        loadErrorMessage = failure.message;
    }
    setBusy(false);
  }

  void selectOwnership(List<VehicleOwnership> values) {
    ownership = values.first;
    if (ownership == VehicleOwnership.owned) {
      selectedSupplier = null;
    }
    notifyListeners();
  }

  void selectVehicleClass(VehicleClass? val) {
    if (val != null) {
      vehicleClass = val;
      notifyListeners();
    }
  }

  void selectSupplier(Party? val) {
    selectedSupplier = val;
    notifyListeners();
  }

  Future<Result<PaginatedResult<Party>>> fetchSuppliersPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
  }) => _partiesRepository.fetchPage(
    pageNumber: pageNumber,
    pageSize: pageSize,
    type: PartyType.supplier,
    search: search,
  );

  Future<void> pickDate(BuildContext context, int type) async {
    final initialDate = switch (type) {
      1 => registrationExpiry ?? DateTime.now(),
      2 => insuranceExpiry ?? DateTime.now(),
      3 => inspectionExpiry ?? DateTime.now(),
      _ => DateTime.now(),
    };

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      if (type == 1) registrationExpiry = picked;
      if (type == 2) insuranceExpiry = picked;
      if (type == 3) inspectionExpiry = picked;
      notifyListeners();
    }
  }

  void submit() {
    final plate = plateNumberController.text.trim();
    final yearText = yearController.text.trim();
    final year = yearText.isEmpty ? null : int.tryParse(yearText);
    if (plate.isEmpty ||
        (ownership == VehicleOwnership.external && selectedSupplier == null) ||
        (yearText.isNotEmpty &&
            (year == null || year < 1900 || year > DateTime.now().year + 1))) {
      return;
    }

    final initialVehicle = request.data is Vehicle
        ? request.data as Vehicle
        : null;

    completer(
      SheetResponse<Vehicle>(
        confirmed: true,
        data: Vehicle(
          id: initialVehicle?.id ?? '',
          plateNumber: plate,
          label: labelController.text.trim().isEmpty
              ? plate
              : labelController.text.trim(),
          vehicleClass: vehicleClass,
          ownership: ownership,
          supplierId: selectedSupplier?.id,
          make: _optional(makeController.text),
          model: _optional(modelController.text),
          year: year,
          registrationExpiry: registrationExpiry,
          insuranceExpiry: insuranceExpiry,
          inspectionExpiry: inspectionExpiry,
          notes: _optional(notesController.text),
        ),
      ),
    );
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    plateNumberController.dispose();
    labelController.dispose();
    makeController.dispose();
    modelController.dispose();
    yearController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
