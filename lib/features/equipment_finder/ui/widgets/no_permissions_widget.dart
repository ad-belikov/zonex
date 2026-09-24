// FILE: .\lib\features\equipment_finder\ui\widgets\no_permissions_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../bloc/ble_scan_bloc.dart';
import '../../bloc/ble_scan_event.dart';

class NoPermissionsWidget extends StatelessWidget {
  const NoPermissionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.gpp_bad, size: 80, color: Colors.redAccent),
          const SizedBox(height: 24),
          const Text(
            'Доступ к Bluetooth отклонен',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Для поиска спортивных тренажеров приложению ZonEx необходимы разрешения на работу с Bluetooth.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Открыть настройки'),
            onPressed: () => openAppSettings(),
          ),
          TextButton(
            onPressed: () =>
                context.read<BleScanBloc>().add(StartScanRequested()),
            child: const Text('Повторить запрос'),
          ),
        ],
      ),
    );
  }
}
