// FILE: .\lib\features\navigation\ui\widgets\main_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/cubit/theme_cubit.dart';
import '../../cubit/navigation_cubit.dart';
import 'ble_scan_action_button.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final NavbarItem activeItem;

  const MainAppBar({super.key, required this.activeItem});

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
    return AppBar(
      title: Text(_getScreenTitle(activeItem)),
      actions: [
        // Кнопка обновления/сканирования отображается только на экране поиска устройств
        if (activeItem == NavbarItem.equipmentFinder)
          const BleScanActionButton(),

        // Кнопка переключения темы с плавной анимацией
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
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
