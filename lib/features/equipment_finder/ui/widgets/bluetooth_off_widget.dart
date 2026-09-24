// FILE: .\lib\features\equipment_finder\ui\widgets\bluetooth_off_widget.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothOffWidget extends StatelessWidget {
  final BluetoothAdapterState adapterState;

  const BluetoothOffWidget({super.key, required this.adapterState});

  @override
  Widget build(BuildContext context) {
    final String stateText = adapterState == BluetoothAdapterState.turningOff
        ? 'Выключение...'
        : 'Отключен';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bluetooth_disabled,
            size: 80,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 24),
          Text(
            'Bluetooth $stateText',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Пожалуйста, включите Bluetooth в настройках вашего телефона для сканирования тренажеров.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (Platform.isAndroid)
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth),
              label: const Text('Включить автоматически'),
              onPressed: () => FlutterBluePlus.turnOn(),
            ),
        ],
      ),
    );
  }
}
