import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/ble_service/ble_service.dart';
import 'ble_connection_event.dart';
import 'ble_connection_state.dart';

class BleConnectionBloc extends Bloc<BleConnectionEvent, BleConnectionState> {
  final BleService _bleService;
  StreamSubscription<BluetoothConnectionState>? _statusSubscription;

  String? _currentTargetAddress;
  // ДОБАВЛЕНО: Счетчик текущих попыток переподключения к тренажеру
  int _reconnectAttempts = 0;
  // ДОБАВЛЕНО: Ссылка на таймер задержки между повторными попытками для предотвращения утечек
  Timer? _reconnectTimer;

  BleConnectionBloc(this._bleService) : super(BleDisconnected()) {
    on<ConnectToDevice>(_onConnect);
    on<DisconnectFromDevice>(_onDisconnect);
    on<UpdateConnectionStatus>(_onStatusUpdate);
    // ДОБАВЛЕНО: Регистрация нового обработчика для атомарных попыток переподключения
    on<RetryConnectionAfterDisconnect>(_onRetryConnection);

    _statusSubscription = _bleService.connectionStateStream.listen((status) {
      if (!isClosed) add(UpdateConnectionStatus(status));
    });
  }

  Future<void> _onConnect(
    ConnectToDevice event,
    Emitter<BleConnectionState> emit,
  ) async {
    _reconnectTimer
        ?.cancel(); // ДОБАВЛЕНО: Сброс таймеров при явном новом подключении
    _reconnectAttempts = 0; // ДОБАВЛЕНО: Сброс счетчика попыток
    _currentTargetAddress = event.address;

    emit(BleConnecting(event.address));
    try {
      await _bleService.connect(event.address);
    } catch (e) {
      emit(BleConnectionError("Не удалось установить соединение"));
    }
  }

  Future<void> _onDisconnect(
    DisconnectFromDevice event,
    Emitter<BleConnectionState> emit,
  ) async {
    _reconnectTimer
        ?.cancel(); // ДОБАВЛЕНО: Отменяем любые фоновые попытки автоконнекта
    _currentTargetAddress = null;
    _reconnectAttempts = 0;
    await _bleService.disconnect();
    emit(BleDisconnected());
  }

  void _onStatusUpdate(
    UpdateConnectionStatus event,
    Emitter<BleConnectionState> emit,
  ) {
    if (event.status == BluetoothConnectionState.connected &&
        _currentTargetAddress != null) {
      _reconnectAttempts =
          0; // ИСПРАВЛЕНО: Успешно подключились — обнуляем счетчик
      _reconnectTimer?.cancel();
      emit(
        BleConnected(
          deviceAddress: _currentTargetAddress!,
          deviceName: "Тренажер",
        ),
      );
    } else if (event.status == BluetoothConnectionState.disconnected) {
      // ИСПРАВЛЕНО: Если связь пропала, но адрес устройства сохранен (не было ручного дисконнекта) -> автореконнект
      if (_currentTargetAddress != null && _reconnectAttempts < 3) {
        emit(
          BleConnecting(_currentTargetAddress!),
        ); // Переводим UI в состояние ожидания
        _scheduleReconnect();
      } else {
        // ИСПРАВЛЕНО: Попытки исчерпаны или это был ручной выход
        _currentTargetAddress = null;
        _reconnectAttempts = 0;
        emit(BleDisconnected());
      }
    }
  }

  // ДОБАВЛЕНО: Логика планирования следующей попытки подключения через 5 секунд
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!isClosed && _currentTargetAddress != null) {
        _reconnectAttempts++;
        add(RetryConnectionAfterDisconnect(_currentTargetAddress!));
      }
    });
  }

  // ДОБАВЛЕНО: Изолированная атомарная попытка переподключения в рамках BLoC-сессии
  Future<void> _onRetryConnection(
    RetryConnectionAfterDisconnect event,
    Emitter<BleConnectionState> emit,
  ) async {
    // Проверяем, что цель подключения не изменилась за время ожидания таймера
    if (_currentTargetAddress == event.address) {
      emit(BleConnecting(event.address));
      try {
        await _bleService.connect(event.address);
      } catch (_) {
        // Ошибка перехватывается, статус disconnected из BleService
        // через _statusSubscription заново вызовет метод _onStatusUpdate и спланирует следующую попытку
      }
    }
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _reconnectTimer?.cancel(); // ДОБАВЛЕНО: Обязательная очистка таймера при закрытии Блока
    return super.close();
  }
}
