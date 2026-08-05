import 'package:fleetgo/core/enums/enums.dart';

class Agreement {
  Agreement({
    required this.id,
    required this.reference,
    required this.name,
    required this.customerId,
    required this.rateModel,
    this.startDate,
    this.endDate,
    this.invoiceGrouping = InvoiceGrouping.perWork,
    this.baseRate = 0,
    this.dutyDays = 0,
    this.includedHours = 0,
    this.overtimeRate = 0,
    this.extraDayRate = 0,
    this.extraTripRate = 0,
    this.vatRate = 5,
    this.driverResponsibility = Responsibility.operator,
    this.fuelResponsibility = Responsibility.operator,
    this.maintenanceResponsibility = Responsibility.operator,
    this.defaultVehicleId,
    this.purchaseOrderReference,
    this.paymentTerms = PaymentTerms.onReceipt,
    this.notes,
    this.defaultExtras = const {},
    this.isArchived = false,
  });

  final String id;
  final String reference;
  final String name;
  final String customerId;
  final RateModel rateModel;
  final DateTime? startDate;
  final DateTime? endDate;
  final InvoiceGrouping invoiceGrouping;
  final num baseRate;
  final int dutyDays;
  final int includedHours;
  final num overtimeRate;
  final num extraDayRate;
  final num extraTripRate;
  final num vatRate;
  final Responsibility driverResponsibility;
  final Responsibility fuelResponsibility;
  final Responsibility maintenanceResponsibility;
  final String? defaultVehicleId;
  final String? purchaseOrderReference;
  final PaymentTerms paymentTerms;
  final String? notes;
  final Map<String, num> defaultExtras;
  bool isArchived;
}
