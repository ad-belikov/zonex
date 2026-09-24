// FILE: .\lib\features\navigation\ui\main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ИСПРАВЛЕНО: Добавлен недостающий импорт для работы с фоновым режимом
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../active_session/bloc/active_session_bloc.dart';
import '../../active_session/bloc/active_session_event.dart';
import '../../active_session/ui/active_session_screen.dart';
import '../../equipment_finder/bloc/ble_scan_bloc.dart';
import '../../equipment_finder/bloc/ble_scan_event.dart';
import '../../equipment_finder/ui/equipment_finder_screen.dart';
import '../../shared/ble_connection_bloc/ble_connection_bloc.dart';
import '../../shared/ble_connection_bloc/ble_connection_state.dart';
import '../cubit/navigation_cubit.dart';
import 'widgets/floating_bottom_navbar.dart';
import 'widgets/main_app_bar.dart';
import 'widgets/placeholder_screens.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NavigationCubit>(
      create: (context) => NavigationCubit(),
      child: MultiBlocListener(
        listeners: [
          BlocListener<NavigationCubit, NavbarItem>(
            listener: (context, activeItem) {
              if (activeItem != NavbarItem.equipmentFinder) {
                context.read<BleScanBloc>().add(StopScanRequested());
              }
            },
          ),
          BlocListener<BleConnectionBloc, BleConnectionState>(
            listener: (context, bleState) {
              bleState.maybeWhen(
                connected: (deviceAddress, deviceName) {
                  context.read<NavigationCubit>().changePage(
                    NavbarItem.activeSession,
                  );
                  context.read<ActiveSessionBloc>().add(
                    StartSession(
                      deviceName: deviceName,
                      deviceAddress: deviceAddress,
                    ),
                  );
                },
                orElse: () {},
              );
            },
          ),
        ],
        child: BlocBuilder<NavigationCubit, NavbarItem>(
          builder: (context, activeItem) {
            // ИСПРАВЛЕНО: Scaffold обернут в компонент WithForegroundTask для
            // корректного взаимодействия плагина с жизненным циклом фонового потока ОС
            return WithForegroundTask(
              child: Scaffold(
                extendBody: true,
                appBar: MainAppBar(activeItem: activeItem),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
