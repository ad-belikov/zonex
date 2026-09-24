// FILE: .\lib\features\active_session\bloc\active_session_event.dart

sealed class ActiveSessionEvent {
  const ActiveSessionEvent();
}

/// Событие старта тренировочной сессии с передачей метаданных устройства
class StartSession extends ActiveSessionEvent {
  final String deviceName;
  final String deviceAddress;

  const StartSession({required this.deviceName, required this.deviceAddress});
}

/// Внутреннее событие для передачи новой порции сырых байт из BLE-сервиса
class UpdateRawData extends ActiveSessionEvent {
  final List<int> rawData;

  const UpdateRawData(this.rawData);
}

/// Событие принудительного завершения или остановки тренировки
class StopSession extends ActiveSessionEvent {
  const StopSession();
}
