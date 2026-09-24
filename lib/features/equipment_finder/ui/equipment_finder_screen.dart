// FILE: .\lib\features\equipment_finder\ui\equipment_finder_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../shared/ble_connection_bloc/ble_connection_bloc.dart';
import '../../shared/ble_connection_bloc/ble_connection_state.dart';
import '../bloc/ble_scan_bloc.dart';
import '../bloc/ble_scan_event.dart';
import '../bloc/ble_scan_state.dart';
// Импортируем наши новые выделенные виджеты
import 'widgets/bluetooth_off_widget.dart';
import 'widgets/discovered_device_list.dart';
import 'widgets/no_permissions_widget.dart';

class EquipmentFinderScreen extends StatelessWidget {
  const EquipmentFinderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BleScanBloc>(
      create: (context) => getIt<BleScanBloc>()..add(StartScanRequested()),
      child: Scaffold(
        body: BlocListener<BleConnectionBloc, BleConnectionState>(
          listener: (context, state) {
            state.maybeWhen(
              error: (message) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message), backgroundColor: Colors.red),
                );
              },
              orElse: () {},
            );
          },
          child: BlocBuilder<BleScanBloc, BleScanState>(
            builder: (context, state) {
              return state.when(
                initial: () => const Center(child: CircularProgressIndicator()),
                noPermissions: () => const NoPermissionsWidget(),
                adapterOff: (adapterState) =>
                    BluetoothOffWidget(adapterState: adapterState),
                inProgress: (results, isScanning) {
                  if (results.isEmpty) {
                    return const Center(
                      child: Text(
                        'Тренажеры поблизости не найдены',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }
                  return DiscoveredDeviceList(devices: results);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
