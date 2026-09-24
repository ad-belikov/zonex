// FILE: .\lib\core\theme\cubit/theme_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../di/injection.dart';
import '../../preferences/preferences_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final PreferencesService _preferencesService;

  // ИСПРАВЛЕНО: При создании кубита считываем тему из сохраненных настроек устройства
  ThemeCubit()
    : _preferencesService = getIt<PreferencesService>(),
      super(_getInitialThemeMode());

  void toggleTheme() {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    // Сохраняем строковое представление в SharedPreferences
    _preferencesService.saveThemeMode(nextMode.name);

    emit(nextMode);
  }

  // Вспомогательный статический метод для парсинга сохраненной строки в Enum ThemeMode
  static ThemeMode _getInitialThemeMode() {
    final String savedModeStr = getIt<PreferencesService>().getThemeMode();

    // Безопасный маппинг строки в ThemeMode
    if (savedModeStr == ThemeMode.light.name) {
      return ThemeMode.light;
    } else if (savedModeStr == ThemeMode.system.name) {
      return ThemeMode.system;
    }
    return ThemeMode.dark; // Дефолтное состояние, если ничего не сохранено
  }
}
