// FILE: .\lib\features\equipment_finder\bloc\ble_scan_state.dart
// FILE: .\lib\features\equipment_finder\bloc\ble_scan_state.dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/discovered_device.dart'; // ДОБАВЛЕНО

part 'ble_scan_state.freezed.dart';

@Freezed()
sealed class BleScanState with _$BleScanState {
  const factory BleScanState.initial() = _Initial;
  const factory BleScanState.noPermissions() = _NoPermissions;
  const factory BleScanState.adapterOff(BluetoothAdapterState adapterState) =
      _AdapterOff;
  const factory BleScanState.inProgress({
    // ИСПРАВЛЕНО: Теперь UI получает чистые модели устройств
    required List<DiscoveredDevice> results,
    required bool isScanning,
  }) = _InProgress;
}
