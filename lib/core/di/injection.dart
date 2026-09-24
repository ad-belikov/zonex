// FILE: .\lib\core\di\injection.dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/active_session/bloc/active_session_bloc.dart'; // ДОБАВЛЕНО для связи с Блоком
import '../../features/equipment_finder/bloc/ble_scan_bloc.dart';
import '../ble_service/ble_service.dart';
import '../fitness/ftp_calculator.dart'; // ДОБАВЛЕНО
import '../preferences/preferences_service.dart';

final getIt = GetIt.instance;

// Функция теперь возвращает Future<void>, так как SharedPreferences требуют await [1]
Future<void> setupDependencies() async {
  // 1. Инициализируем SharedPreferences прямо при старте приложения [1]
  final prefs = await SharedPreferences.getInstance();

  // 2. Регистрируем наш PreferencesService как Singleton, передавая туда готовый инстанс настроек [1]
  getIt.registerLazySingleton<PreferencesService>(
    () => PreferencesService(prefs),
  );

  // Базовые сервисы [1]
  getIt.registerLazySingleton<BleService>(() => BleService());

  // ДОБАВЛЕНО: Регистрируем калькулятор FTP как Singleton
  getIt.registerLazySingleton<FtpCalculator>(
    () => FtpCalculator(getIt<PreferencesService>()),
  );

  // Фабрики блоков [1]
  getIt.registerFactory<BleScanBloc>(() => BleScanBloc(getIt<BleService>()));

  // ИСПРАВЛЕНО/ДОБАВЛЕНО: Регистрируем фабрику ActiveSessionBloc в контейнере DI,
  // передавая туда сразу две зависимости — BleService и FtpCalculator.
  getIt.registerFactory<ActiveSessionBloc>(
    () => ActiveSessionBloc(getIt<BleService>(), getIt<FtpCalculator>()),
  );
}
