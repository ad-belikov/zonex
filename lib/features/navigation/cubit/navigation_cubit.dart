import 'package:flutter_bloc/flutter_bloc.dart';

enum NavbarItem {
  equipmentFinder,
  activeSession,
  activityInsights,
  preferences,
  account,
}

class NavigationCubit extends Cubit<NavbarItem> {
  NavigationCubit() : super(NavbarItem.equipmentFinder);
  void changePage(NavbarItem item) => emit(item);
}
