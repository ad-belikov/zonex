import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/ble_service/ble_service.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/cubit/theme_cubit.dart';
import '../../active_session/bloc/active_session_bloc.dart';
import '../../active_session/bloc/active_session_event.dart';
import '../../active_session/ui/active_session_screen.dart';
import '../../equipment_finder/ui/equipment_finder_screen.dart';
import '../../shared/ble_connection_bloc/ble_connection_bloc.dart'; // ДОБАВЛЕНО
import '../../shared/ble_connection_bloc/ble_connection_state.dart'; // ДОБАВЛЕНО
import '../cubit/navigation_cubit.dart';
import 'widgets/floating_bottom_navbar.dart';
import 'widgets/placeholder_screens.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  String _getScreenTitle(NavbarItem item) {
    switch (item) {
      case NavbarItem.equipmentFinder:
        return 'ZonEx - Equipment Finder';
      case NavbarItem.activeSession:
        return 'Active Session';
      case NavbarItem.activityInsights:
        return 'Activity Insights';
      case NavbarItem.preferences:
        return 'Preferences';
      case NavbarItem.account:
        return 'Account Profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    final BleService bleService = getIt<BleService>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => NavigationCubit()),
        BlocProvider(create: (context) => ActiveSessionBloc(bleService)),
      ],
      // ДОБАВЛЕНО: Мульти-листенер для одновременного контроля переключения вкладок и состояния BLE-сессии
      child: MultiBlocListener(
        listeners: [
          BlocListener<NavigationCubit, NavbarItem>(
            listener: (context, activeItem) {
              if (activeItem != NavbarItem.equipmentFinder) {
                bleService.stopScan();
              }
            },
          ),
          // ДОБАВЛЕНО: Слушатель статуса подключения для автоматизации перехода к тренировке
          BlocListener<BleConnectionBloc, BleConnectionState>(
            listener: (context, bleState) {
              if (bleState is BleConnected) {
                // ИСПРАВЛЕНО: Автоматически переключаем нижнюю панель на вкладку тренировки (Session)
                context.read<NavigationCubit>().changePage(
                  NavbarItem.activeSession,
                );

                // ИСПРАВЛЕНО: Автоматически запускаем сессию чтения и сглаживания данных тренажера
                context.read<ActiveSessionBloc>().add(
                  StartSession(
                    deviceName: bleState.deviceName,
                    deviceAddress: bleState.deviceAddress,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<NavigationCubit, NavbarItem>(
          builder: (context, activeItem) {
            return Scaffold(
              extendBody: true,
              appBar: AppBar(
                title: Text(_getScreenTitle(activeItem)),
                actions: [
                  if (activeItem == NavbarItem.equipmentFinder)
                    StreamBuilder<bool>(
                      stream: FlutterBluePlus.isScanning,
                      builder: (context, snapshot) {
                        final isScanning = snapshot.data ?? false;

                        return isScanning
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.redAccent,
                                    ),
                                    tooltip: 'Остановить сканирование',
                                    onPressed: () => bleService.stopScan(),
                                  ),
                                ],
                              )
                            : IconButton(
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Обновить список',
                                onPressed: () => bleService.startScan(),
                              );
                      },
                    ),
                  BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, themeMode) {
                      final isDark = themeMode == ThemeMode.dark;
                      return IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            key: ValueKey<bool>(isDark),
                            color: isDark ? Colors.amberAccent : Colors.orange,
                          ),
                        ),
                        onPressed: () =>
                            context.read<ThemeCubit>().toggleTheme(),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Stack(
                children: [
                  IndexedStack(
                    index: activeItem.index,
                    children: const [
                      EquipmentFinderScreen(),
                      ActiveSessionScreen(),
                      PlaceholderScreen(
                        title: 'Activity Insights',
                        icon: Icons.insert_chart_outlined,
                        accentColor: Colors.purpleAccent,
                      ),
                      PlaceholderScreen(
                        title: 'Preferences',
                        icon: Icons.tune,
                        accentColor: Colors.orangeAccent,
                      ),
                      PlaceholderScreen(
                        title: 'Account Profile',
                        icon: Icons.account_circle_outlined,
                        accentColor: Colors.tealAccent,
                      ),
                    ],
                  ),
                  const Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: FloatingBottomNavbar(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
