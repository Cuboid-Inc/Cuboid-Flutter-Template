import 'package:cuboid_flutter_template/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

/// All display formatting, routed through [AppConfig].
///
/// Uses the default (en_US) locale data baked into `intl` with explicit
/// patterns, so no `initializeDateFormatting()` call is required.
abstract final class Formatters {
  static String date(DateTime value) =>
      DateFormat(AppConfig.datePattern).format(value);

  static String time(DateTime value) =>
      DateFormat(AppConfig.timePattern).format(value);

  static String dateTime(DateTime value) =>
      DateFormat(AppConfig.dateTimePattern).format(value);

  static String monthYear(DateTime value) =>
      DateFormat(AppConfig.monthYearPattern).format(value);
}
