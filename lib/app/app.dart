// FILE: .\lib\app\app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Глобальные сервисы ядра
// ДОБАВЛЕНО/ИСПРАВЛЕНО: Добавлен импорт BleService, чтобы исправить ошибку "isn't a type"
import '../core/ble_service/ble_service.dart';
import '../core/di/injection.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/cubit/theme_cubit.dart';
// Точные относительные пути к Блокам фич приложения
import '../features/active_session/bloc/active_session_bloc.dart';
import '../features/navigation/ui/main_screen.dart';
import '../features/shared/ble_connection_bloc/ble_connection_bloc.dart';

class ZonExApp extends StatelessWidget {
  const ZonExApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Теперь ActiveSessionBloc не пересоздается при изменении стейта MainScreen.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(
          create: (context) => BleConnectionBloc(getIt<BleService>()),
        ),
        // ИСПРАВЛЕНО: Извлекаем Блок целиком из getIt со всеми его зависимостями.
        // Это устраняет ошибку "2 positional arguments expected but 1 found".
        BlocProvider(create: (context) => getIt<ActiveSessionBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'ZonEx',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
