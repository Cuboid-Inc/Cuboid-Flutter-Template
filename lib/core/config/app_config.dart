/// Centralized app configuration: locale, currency, and date/time patterns.
abstract final class AppConfig {
  static const appName = 'Cuboid Flutter Template';
  static const locale = 'en_AE';
  static const currencyCode = 'AED';
  static const datePattern = 'dd MMM yyyy';
  static const timePattern = 'h:mm a';
  static const dateTimePattern = 'dd MMM yyyy, h:mm a';
  static const monthYearPattern = 'MMMM yyyy';

  /// Document number prefixes. Invoice prefix is tenant-configurable
  /// (business_profiles.invoice_prefix); these are fixed system-wide and
  /// mirrored as literals in the matching supabase/migrations SQL functions.
  static const agreementPrefix = 'AGR';
  static const workOrderPrefix = 'WO';
  static const settlementPrefix = 'SET';
}
