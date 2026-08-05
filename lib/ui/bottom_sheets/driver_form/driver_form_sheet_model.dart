import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/driver.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class DriverFormSheetModel extends BaseViewModel {
  DriverFormSheetModel({required this.completer, required this.request})
    : _partiesRepository = locator<PartiesRepository>() {
    if (request.data is Driver) {
      final initialDriver = request.data as Driver;
      nameController.text = initialDriver.name;
      phoneController.text = initialDriver.phone ?? '';
      licenceNumberController.text = initialDriver.licenceNumber ?? '';
      identityReferenceController.text = initialDriver.identityReference ?? '';
      notesController.text = initialDriver.notes ?? '';
      employment = initialDriver.employment;
      licenceExpiry = initialDriver.licenceExpiry;
      identityExpiry = initialDriver.identityExpiry;
    }
  }

  final Function(SheetResponse response) completer;
  final SheetRequest request;
  final PartiesRepository _partiesRepository;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final licenceNumberController = TextEditingController();
  final identityReferenceController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Responsibility employment = Responsibility.operator;
  Party? selectedSupplier;
  DateTime? licenceExpiry;
  DateTime? identityExpiry;

  String? loadErrorMessage;

  String? get errorMessage => loadErrorMessage;

  bool get isEditing => request.data is Driver;

  Future<void> init() async {
    final initialDriver = request.data is Driver
        ? request.data as Driver
        : null;
    final supplierId = initialDriver?.supplierId;
    if (!isEditing ||
        employment != Responsibility.customer ||
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

  void selectEmployment(List<Responsibility> values) {
    employment = values.first;
    if (employment == Responsibility.operator) {
      selectedSupplier = null;
    }
    notifyListeners();
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
      1 => licenceExpiry ?? DateTime.now(),
      2 => identityExpiry ?? DateTime.now(),
      _ => DateTime.now(),
    };

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      if (type == 1) licenceExpiry = picked;
      if (type == 2) identityExpiry = picked;
      notifyListeners();
    }
  }

  void submit() {
    final name = nameController.text.trim();
    if (name.isEmpty ||
        (employment == Responsibility.customer && selectedSupplier == null)) {
      return;
    }
    final initialDriver = request.data is Driver
        ? request.data as Driver
        : null;

    completer(
      SheetResponse<Driver>(
        confirmed: true,
        data: Driver(
          id: initialDriver?.id ?? '',
          name: name,
          phone: _optional(phoneController.text),
          licenceNumber: _optional(licenceNumberController.text),
          licenceExpiry: licenceExpiry,
          identityReference: _optional(identityReferenceController.text),
          identityExpiry: identityExpiry,
          employment: employment,
          supplierId: selectedSupplier?.id,
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
    nameController.dispose();
    phoneController.dispose();
    licenceNumberController.dispose();
    identityReferenceController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
