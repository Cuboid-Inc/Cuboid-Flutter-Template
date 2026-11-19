import 'package:cuboid_flutter_template/core/services/message_service.dart';
import 'package:cuboid_flutter_template/core/services/navigation_service.dart';
import 'package:get_it/get_it.dart';
// @cuboid-import

final locator = GetIt.instance;

Future<void> setupLocator() async {
  locator.registerLazySingleton<NavigationService>(() => NavigationService());
  locator.registerLazySingleton<MessageService>(() => MessageService());
  // @cuboid-service
}
