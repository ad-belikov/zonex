abstract class ActiveSessionEvent {}

// ДОБАВЛЕНО: Событие старта тренировочной сессии с передачей метаданных устройства
class StartSession extends ActiveSessionEvent {
  final String deviceName;
  final String deviceAddress;

  StartSession({required this.deviceName, required this.deviceAddress});
}

// ДОБАВЛЕНО: Внутреннее событие для передачи новой порции сырых байт из BLE-сервиса
class UpdateRawData extends ActiveSessionEvent {
  final List<int> rawData;

  UpdateRawData(this.rawData);
}

// ДОБАВЛЕНО: Событие принудительного завершения или остановки тренировки
class StopSession extends ActiveSessionEvent {}
