// FILE: .\lib\features\equipment_finder\ui\widgets\discovered_device_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ble_parsers/ble_parser.dart';
import '../../../shared/ble_connection_bloc/ble_connection_bloc.dart';
import '../../../shared/ble_connection_bloc/ble_connection_event.dart';
import '../../../shared/ble_connection_bloc/ble_connection_state.dart';
import '../../bloc/ble_scan_bloc.dart';
import '../../bloc/ble_scan_event.dart';
import '../../models/discovered_device.dart';

class DiscoveredDeviceList extends StatelessWidget {
  final List<DiscoveredDevice> devices;

  const DiscoveredDeviceList({super.key, required this.devices});

  IconData _getEquipmentIcon(EquipmentType type) {
    switch (type) {
      case EquipmentType.rower:
        return Icons.rowing;
      case EquipmentType.bike:
        return Icons.directions_bike;
      case EquipmentType.treadmill:
        return Icons.directions_run;
      case EquipmentType.stepper:
        return Icons.height;
      default:
        return Icons.bluetooth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120, top: 8),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];

        return BlocBuilder<BleConnectionBloc, BleConnectionState>(
          builder: (context, state) {
            Color iconColor = Colors.grey;
            bool isThisConnecting = false;

            state.maybeWhen(
              connected: (deviceAddress, deviceName) {
                if (deviceAddress == device.id) iconColor = Colors.green;
              },
              // ИСПРАВЛЕНО: Учтен аргумент attempt через прочерк (_)
              connecting: (connectingAddress, _) {
                if (connectingAddress == device.id) {
                  iconColor = Colors.orangeAccent;
                  isThisConnecting = true;
                }
              },
              orElse: () {},
            );

            return ListTile(
              title: Text(device.name),
              subtitle: Text('${device.id}\nRSSI: ${device.rssi} dBm'),
              trailing: isThisConnecting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Icon(
                      _getEquipmentIcon(device.type),
                      color: iconColor,
                      size: 28,
                    ),
              onTap: isThisConnecting
                  ? null
                  : () {
                      context.read<BleScanBloc>().add(StopScanRequested());
                      context.read<BleConnectionBloc>().add(
                        ConnectToDevice(device.id),
                      );
                    },
            );
          },
        );
      },
    );
  }
}
