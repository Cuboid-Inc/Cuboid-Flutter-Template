import 'package:cuboid_flutter_template/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

/// All display formatting, routed through [AppConfig].
///
/// Uses the default (en_US) locale data baked into `intl` with explicit
/// patterns, so no `initializeDateFormatting()` call is required.
abstract final class Formatters {
  static final _rawMoney = NumberFormat('#,##0.00', 'en_US');

  static String money(num amount) {
    final code = AppConfig.currencyCode;
    if (amount < 0) {
      return '$code -${_rawMoney.format(amount.abs())}';
    }
    return '$code ${_rawMoney.format(amount)}';
  }

  static String signedMoney(num amount) =>
      '${amount < 0
          ? '−'
          : amount > 0
          ? '+'
          : ''}${money(amount.abs())}';

  static String rawMoney(num amount) {
    if (amount < 0) {
      return '-${_rawMoney.format(amount.abs())}';
    }
    return _rawMoney.format(amount);
  }

  static String date(DateTime value) =>
      DateFormat(AppConfig.datePattern).format(value);

  static String time(DateTime value) =>
      DateFormat(AppConfig.timePattern).format(value);

  static String dateTime(DateTime value) =>
      DateFormat(AppConfig.dateTimePattern).format(value);

  static String monthYear(DateTime value) =>
      DateFormat(AppConfig.monthYearPattern).format(value);
}
