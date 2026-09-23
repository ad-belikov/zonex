import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../cubit/navigation_cubit.dart';

class FloatingBottomNavbar extends StatelessWidget {
  const FloatingBottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundBlack,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: BlocBuilder<NavigationCubit, NavbarItem>(
            builder: (context, currentItem) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: NavbarItem.values.map((item) {
                  final isSelected = currentItem == item;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        context.read<NavigationCubit>().changePage(item),
                    child: AnimatedScale(
                      scale: isSelected ? 1.1 : 1.0,
                      duration: AppTheme.animationDuration,
                      curve: AppTheme.animationCurve,
                      child: AnimatedOpacity(
                        opacity: isSelected ? 1.0 : 0.5,
                        duration: AppTheme.animationDuration,
                        child: SizedBox(
                          width: 65,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIcon(item),
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.inactive,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getLabel(item),
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.inactive,
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _getIcon(NavbarItem item) {
    switch (item) {
      case NavbarItem.equipmentFinder:
        return Icons.search;
      case NavbarItem.activeSession:
        return Icons.play_circle_outline;
      case NavbarItem.activityInsights:
        return Icons.bar_chart;
      case NavbarItem.preferences:
        return Icons.settings;
      case NavbarItem.account:
        return Icons.person;
    }
  }

  String _getLabel(NavbarItem item) {
    switch (item) {
      case NavbarItem.equipmentFinder:
        return 'Finder';
      case NavbarItem.activeSession:
        return 'Session';
      case NavbarItem.activityInsights:
        return 'Insights';
      case NavbarItem.preferences:
        return 'Prefs';
      case NavbarItem.account:
        return 'Account';
    }
  }
}
