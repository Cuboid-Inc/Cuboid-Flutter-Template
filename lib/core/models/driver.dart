import 'package:nemara_homes/core/enums/enums.dart';

class Driver {
  Driver({
    required this.id,
    required this.name,
    this.phone,
    this.licenceNumber,
    this.licenceExpiry,
    this.identityReference,
    this.identityExpiry,
    this.employment = Responsibility.operator,
    this.supplierId,
    this.notes,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String? phone;
  final String? licenceNumber;
  final DateTime? licenceExpiry;
  final String? identityReference;
  final DateTime? identityExpiry;
  final Responsibility employment;
  final String? supplierId;
  final String? notes;
  bool isArchived;
}
