abstract class BleConnectionState {}

class BleDisconnected extends BleConnectionState {}

// ИСПРАВЛЕНО: Теперь состояние хранит адрес подключаемого устройства для точечной анимации в UI
class BleConnecting extends BleConnectionState {
  final String connectingAddress;
  BleConnecting(this.connectingAddress);
}

// ИСПРАВЛЕНО: Состояние содержит точные параметры подключенного тренажера
class BleConnected extends BleConnectionState {
  final String deviceAddress;
  final String deviceName;

  BleConnected({required this.deviceAddress, required this.deviceName});
}

class BleConnectionError extends BleConnectionState {
  final String message;
  BleConnectionError(this.message);
}
