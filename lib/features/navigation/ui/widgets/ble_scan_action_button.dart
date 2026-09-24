// FILE: .\lib\features\navigation\ui\widgets\ble_scan_action_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../equipment_finder/bloc/ble_scan_bloc.dart';
import '../../../equipment_finder/bloc/ble_scan_event.dart';

class BleScanActionButton extends StatelessWidget {
  const BleScanActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FlutterBluePlus.isScanning,
      builder: (context, snapshot) {
        final isScanning = snapshot.data ?? false;

        if (isScanning) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                tooltip: 'Остановить сканирование',
                onPressed: () =>
                    context.read<BleScanBloc>().add(StopScanRequested()),
              ),
            ],
          );
        }

        return IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Обновить список',
          onPressed: () =>
              context.read<BleScanBloc>().add(StartScanRequested()),
        );
      },
    );
  }
}
