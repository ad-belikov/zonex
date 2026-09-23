import 'package:get_it/get_it.dart';

import '../ble_service/ble_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<BleService>(() => BleService());
}
