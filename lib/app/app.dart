import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/ble_service/ble_service.dart';
import '../core/di/injection.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/cubit/theme_cubit.dart';
import '../features/navigation/ui/main_screen.dart';
import '../features/shared/ble_connection_bloc/ble_connection_bloc.dart';

class ZonExApp extends StatelessWidget {
  const ZonExApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(
          create: (context) => BleConnectionBloc(getIt<BleService>()),
        ),
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
