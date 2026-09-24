// FILE: lib/core/ble_service/ble_service.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  final List<StreamSubscription<List<int>>> _characteristicSubs = [];

  // Флаг для предотвращения race condition при частых реконнектах
  bool _isConnectingProcessActive = false;

  final StreamController<List<int>> _rawDataController =
      StreamController<List<int>>.broadcast();
  final StreamController<BluetoothConnectionState> _stateController =
      StreamController<BluetoothConnectionState>.broadcast();

  Stream<List<int>> get rawDataStream => _rawDataController.stream;
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _stateController.stream;
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> startScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Ошибка запуска сканирования BLE: $e');
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(String address) async {
    if (_isConnectingProcessActive) {
      debugPrint(
        'BLE: Процесс подключения уже запущен, игнорируем дублирующий вызов.',
      );
      return;
    }

    final device = BluetoothDevice.fromId(address);
    _isConnectingProcessActive = true;

    try {
      await _establishConnection(device);
    } catch (e) {
      debugPrint('Исключение при подключении к устройству: $e');
      rethrow;
    } finally {
      _isConnectingProcessActive = false;
    }
  }

  Future<void> _clearDataSubscriptions() async {
    // ИСПРАВЛЕНО: Безопасный обход элементов и гарантированное закрытие подписок
    for (final sub in List<StreamSubscription<List<int>>>.from(
      _characteristicSubs,
    )) {
      await sub.cancel();
    }
    _characteristicSubs.clear();
  }

  Future<void> _establishConnection(BluetoothDevice device) async {
    // Безопасно зачищаем старые подписки на состояние и характеристики перед новым коннектом
    await _connectionStateSub?.cancel();
    await _clearDataSubscriptions();

    _connectionStateSub = device.connectionState.listen((state) {
      if (!_stateController.isClosed) _stateController.add(state);
    });

    try {
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        throw Exception('Bluetooth адаптер выключен');
      }

      // Подключаемся (параметр license удален, так как он приводил к ошибке компиляции)
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 10),
      );

      _connectedDevice = device;
      final List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify ||
              characteristic.properties.indicate) {
            await characteristic.setNotifyValue(true);

            final sub = characteristic.onValueReceived.listen((value) {
              if (!_rawDataController.isClosed) {
                _rawDataController.add(value);
              }
            });
            _characteristicSubs.add(sub);
          }
        }
      }
    } catch (e) {
      debugPrint('BLE Error: Ошибка соединения: $e');
      if (!_stateController.isClosed) {
        _stateController.add(BluetoothConnectionState.disconnected);
      }
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _clearDataSubscriptions();
    await _connectionStateSub?.cancel();
    _connectionStateSub = null;

    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }

    if (!_stateController.isClosed) {
      _stateController.add(BluetoothConnectionState.disconnected);
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _rawDataController.close();
    await _stateController.close();
  }
}
