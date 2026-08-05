import 'package:cuboid_flutter_template/core/enums/enums.dart';

class BusinessProfile {
  const BusinessProfile({
    required this.legalName,
    this.arabicLegalName,
    this.trn,
    this.tradeLicence,
    this.address,
    this.city,
    this.country = 'United Arab Emirates',
    this.phone,
    this.email,
    this.brandColor = 0xFF11B2F3,
    this.footer,
    this.paymentInstructions,
    this.invoicePrefix = 'INV',
    this.useCustomLetterhead = false,
    this.letterheadPath,
    this.letterheadMarginTopMm = 55,
    this.letterheadMarginBottomMm = 25,
    this.letterheadMarginLeftMm = 20,
    this.letterheadMarginRightMm = 20,
  });

  final String legalName;
  final String? arabicLegalName;
  final String? trn;
  final String? tradeLicence;
  final String? address;
  final String? city;
  final String country;
  final String? phone;
  final String? email;
  final int brandColor;
  final String? footer;
  final String? paymentInstructions;
  final String invoicePrefix;

  /// True to use the uploaded letterhead as the PDF background instead of
  /// the programmatic header/footer below.
  final bool useCustomLetterhead;

  /// Absolute local path to the uploaded letterhead background (always a
  /// PNG once stored, regardless of the original upload format).
  final String? letterheadPath;
  final double letterheadMarginTopMm;
  final double letterheadMarginBottomMm;
  final double letterheadMarginLeftMm;
  final double letterheadMarginRightMm;

  String get initials => legalName
      .split(' ')
      .where((value) => value.isNotEmpty)
      .take(2)
      .map((value) => value[0])
      .join()
      .toUpperCase();
}

class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    this.role = StaffRole.staff,
    this.accessPacks = const {},
    this.status = StaffStatus.active,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String email;
  final StaffRole role;
  final Set<AccessPack> accessPacks;
  final StaffStatus status;
  final bool isArchived;
}
