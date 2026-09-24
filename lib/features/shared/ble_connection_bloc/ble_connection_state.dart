// FILE: .\lib\features\shared\ble_connection_bloc\ble_connection_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ble_connection_state.freezed.dart';

@Freezed()
sealed class BleConnectionState with _$BleConnectionState {
  const factory BleConnectionState.disconnected() = _Disconnected;

  // ИСПРАВЛЕНО: Добавлен необязательный параметр attempt для отображения на UI
  const factory BleConnectionState.connecting(
    String connectingAddress, {
    @Default(1) int attempt,
  }) = _Connecting;

  const factory BleConnectionState.connected({
    required String deviceAddress,
    required String deviceName,
  }) = _Connected;

  const factory BleConnectionState.error(String message) = _Error;
}
