// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedLocatorGenerator
// **************************************************************************

// ignore_for_file: public_member_api_docs, implementation_imports, depend_on_referenced_packages

import 'package:stacked_services/src/bottom_sheet/bottom_sheet_service.dart';
import 'package:stacked_services/src/dialog/dialog_service.dart';
import 'package:stacked_services/src/navigation/navigation_service.dart';
import 'package:stacked_services/src/snackbar/snackbar_service.dart';
import 'package:stacked_shared/stacked_shared.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/home/data/home_repository.dart';
import '../features/money/data/money_repository.dart';
import '../features/more/data/agreement_repository.dart';
import '../features/more/data/business_profile_repository.dart';
import '../features/more/data/driver_repository.dart';
import '../features/more/data/more_repository.dart';
import '../features/more/data/route_rate_repository.dart';
import '../features/more/data/staff_repository.dart';
import '../features/more/data/vehicle_repository.dart';
import '../features/parties/data/parties_repository.dart';
import '../features/reports/data/reports_repository.dart';
import '../features/shell/shell_service.dart';
import '../features/work/data/work_repository.dart';

final locator = StackedLocator.instance;

Future<void> setupLocator({
  String? environment,
  EnvironmentFilter? environmentFilter,
}) async {
  // Register environments
  locator.registerEnvironment(
    environment: environment,
    environmentFilter: environmentFilter,
  );

  // Register dependencies
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => DialogService());
  locator.registerLazySingleton(() => BottomSheetService());
  locator.registerLazySingleton(() => SnackbarService());
  locator.registerLazySingleton(() => ShellService());
  locator.registerLazySingleton(() => AuthRepository());
  locator.registerLazySingleton(() => PartiesRepository());
  locator.registerLazySingleton(() => HomeRepository());
  locator.registerLazySingleton(() => MoneyRepository());
  locator.registerLazySingleton(() => MoreRepository());
  locator.registerLazySingleton(() => VehicleRepository());
  locator.registerLazySingleton(() => DriverRepository());
  locator.registerLazySingleton(() => AgreementRepository());
  locator.registerLazySingleton(() => RouteRateRepository());
  locator.registerLazySingleton(() => StaffRepository());
  locator.registerLazySingleton(() => BusinessProfileRepository());
  locator.registerLazySingleton(() => ReportsRepository());
  locator.registerLazySingleton(() => WorkRepository());
}
