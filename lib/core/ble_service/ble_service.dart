import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  final List<StreamSubscription<List<int>>> _characteristicSubs = [];

  final StreamController<List<int>> _rawDataController =
      StreamController<List<int>>.broadcast();

  final StreamController<BluetoothConnectionState> _stateController =
      StreamController<BluetoothConnectionState>.broadcast();

  Stream<List<int>> get rawDataStream => _rawDataController.stream;
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _stateController.stream;

  // ИСПРАВЛЕНО: Удалены лишние флаги автореконнекта, логика перенесена в BLoC слой
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> startScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Ошибка запуска сканирования BLE: $e');
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(String address) async {
    final device = BluetoothDevice.fromId(address);
    await _establishConnection(device);
  }

  Future<void> _clearDataSubscriptions() async {
    for (var sub in _characteristicSubs) {
      await sub.cancel();
    }
    _characteristicSubs.clear();
  }

  Future<void> _establishConnection(BluetoothDevice device) async {
    await _connectionStateSub?.cancel();

    _connectionStateSub = device.connectionState.listen((state) {
      if (!_stateController.isClosed) {
        _stateController.add(
          state,
        ); // ИСПРАВЛЕНО: Просто транслируем стейты наверх в Блок
      }
    });

    try {
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 10),
      );
      _connectedDevice = device;

      await _clearDataSubscriptions();

      final List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify ||
              characteristic.properties.indicate) {
            await characteristic.setNotifyValue(true);

            final sub = characteristic.lastValueStream.listen((value) {
              if (!_rawDataController.isClosed) {
                _rawDataController.add(value);
              }
            });
            _characteristicSubs.add(sub);
          }
        }
      }
    } catch (e) {
      if (!_stateController.isClosed) {
        _stateController.add(BluetoothConnectionState.disconnected);
      }
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _clearDataSubscriptions();
    await _connectionStateSub?.cancel();
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
    if (!_stateController.isClosed) {
      _stateController.add(BluetoothConnectionState.disconnected);
    }
  }

  void dispose() {
    _clearDataSubscriptions();
    _rawDataController.close();
    _stateController.close();
  }
}
