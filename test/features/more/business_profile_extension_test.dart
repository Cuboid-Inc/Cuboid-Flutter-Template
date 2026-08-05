import 'package:cuboid_flutter_template/core/models/business_profile.dart';
import 'package:cuboid_flutter_template/features/more/data/business_profile_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps and writes all business profile fields', () {
    const profile = BusinessProfile(
      legalName: 'FleetGo LLC',
      arabicLegalName: 'فليت جو',
      trn: 'TRN-1',
      tradeLicence: 'LIC-1',
      address: 'Street 1',
      city: 'Dubai',
      country: 'UAE',
      phone: '+971500000000',
      email: 'info@example.com',
      brandColor: 123,
      footer: 'Footer',
      paymentInstructions: 'Pay by bank transfer',
      invoicePrefix: 'FG',
      useCustomLetterhead: true,
      letterheadPath: '/tmp/header.png',
      letterheadMarginTopMm: 10.5,
      letterheadMarginBottomMm: 11.5,
      letterheadMarginLeftMm: 12.5,
      letterheadMarginRightMm: 13.5,
    );

    final row = profile.toRow('tenant-1');
    expect(row['tenant_id'], 'tenant-1');
    expect(row['legal_name'], 'Cuboid Flutter Template LLC');
    expect(row['arabic_legal_name'], 'فليت جو');
    expect(row['brand_color'], 123);
    expect(row['use_custom_letterhead'], isTrue);
    expect(row['letterhead_margin_right_mm'], 13.5);

    final mapped = BusinessProfileRow.fromRow(row);
    expect(mapped.legalName, profile.legalName);
    expect(mapped.arabicLegalName, profile.arabicLegalName);
    expect(mapped.country, 'UAE');
    expect(mapped.brandColor, 123);
    expect(mapped.invoicePrefix, 'FG');
    expect(mapped.letterheadMarginTopMm, 10.5);
    expect(mapped.letterheadMarginBottomMm, 11.5);
    expect(mapped.letterheadMarginLeftMm, 12.5);
    expect(mapped.letterheadMarginRightMm, 13.5);
  });
}
