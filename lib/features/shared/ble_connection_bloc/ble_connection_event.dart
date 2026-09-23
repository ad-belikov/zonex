import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class BleConnectionEvent {}

class ConnectToDevice extends BleConnectionEvent {
  final String address;
  ConnectToDevice(this.address);
}

class DisconnectFromDevice extends BleConnectionEvent {}

class UpdateConnectionStatus extends BleConnectionEvent {
  final BluetoothConnectionState status;
  UpdateConnectionStatus(this.status);
}

// ДОБАВЛЕНО: Новое внутреннее событие для корректного старта автоподключения внутри BLoC архитектуры
class RetryConnectionAfterDisconnect extends BleConnectionEvent {
  final String address;
  RetryConnectionAfterDisconnect(this.address);
}
