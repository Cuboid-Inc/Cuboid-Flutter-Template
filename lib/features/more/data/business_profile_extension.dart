import 'package:fleetgo/core/models/business_profile.dart';

extension BusinessProfileRow on BusinessProfile {
  Map<String, dynamic> toRow(String tenantId) => {
    'tenant_id': tenantId,
    'legal_name': legalName,
    'arabic_legal_name': arabicLegalName,
    'trn': trn,
    'trade_licence': tradeLicence,
    'address': address,
    'city': city,
    'country': country,
    'phone': phone,
    'email': email,
    'brand_color': brandColor,
    'footer': footer,
    'payment_instructions': paymentInstructions,
    'invoice_prefix': invoicePrefix,
    'use_custom_letterhead': useCustomLetterhead,
    'letterhead_path': letterheadPath,
    'letterhead_margin_top_mm': letterheadMarginTopMm,
    'letterhead_margin_bottom_mm': letterheadMarginBottomMm,
    'letterhead_margin_left_mm': letterheadMarginLeftMm,
    'letterhead_margin_right_mm': letterheadMarginRightMm,
  };

  static BusinessProfile fromRow(Map<String, dynamic> row) => BusinessProfile(
    legalName: row['legal_name'] as String,
    arabicLegalName: row['arabic_legal_name'] as String?,
    trn: row['trn'] as String?,
    tradeLicence: row['trade_licence'] as String?,
    address: row['address'] as String?,
    city: row['city'] as String?,
    country: row['country'] as String,
    phone: row['phone'] as String?,
    email: row['email'] as String?,
    brandColor: (row['brand_color'] as num).toInt(),
    footer: row['footer'] as String?,
    paymentInstructions: row['payment_instructions'] as String?,
    invoicePrefix: row['invoice_prefix'] as String,
    useCustomLetterhead: row['use_custom_letterhead'] as bool,
    letterheadPath: row['letterhead_path'] as String?,
    letterheadMarginTopMm: (row['letterhead_margin_top_mm'] as num).toDouble(),
    letterheadMarginBottomMm: (row['letterhead_margin_bottom_mm'] as num)
        .toDouble(),
    letterheadMarginLeftMm: (row['letterhead_margin_left_mm'] as num)
        .toDouble(),
    letterheadMarginRightMm: (row['letterhead_margin_right_mm'] as num)
        .toDouble(),
  );
}
