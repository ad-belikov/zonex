// FILE: .\lib\features\shared\ble_connection_bloc\ble_connection_bloc.dart
import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/ble_service/ble_service.dart';
import 'ble_connection_event.dart';
import 'ble_connection_state.dart';

class BleConnectionBloc extends Bloc<BleConnectionEvent, BleConnectionState> {
  final BleService _bleService;
  StreamSubscription<BluetoothConnectionState>? _statusSubscription;

  String? _currentTargetAddress;
  int _reconnectAttempts = 0;
  bool _isManualDisconnect = false;
  static const int _maxReconnectAttempts = 3;

  BleConnectionBloc(this._bleService)
    : super(const BleConnectionState.disconnected()) {
    on<ConnectToDevice>(_onConnect, transformer: sequential());
    on<DisconnectFromDevice>(_onDisconnect, transformer: sequential());
    on<UpdateConnectionStatus>(_onStatusUpdate);

    // ИСПРАВЛЕНО: Интегрирован реактивный перезапускаемый трансформер с задержкой (Debounce/Delay)
    on<RetryConnectionAfterDisconnect>(
      _onRetryConnection,
      transformer: (events, mapper) {
        return restartable<RetryConnectionAfterDisconnect>().call(
          events.delay(const Duration(seconds: 5)),
          mapper,
        );
      },
    );

    _statusSubscription = _bleService.connectionStateStream.listen((status) {
      if (!isClosed) add(UpdateConnectionStatus(status));
    });
  }

  Future<void> _onConnect(
    ConnectToDevice event,
    Emitter<BleConnectionState> emit,
  ) async {
    _reconnectAttempts = 0;
    _currentTargetAddress = event.address;
    _isManualDisconnect = false;

    emit(BleConnectionState.connecting(event.address));
    try {
      await _bleService.connect(event.address);
    } catch (e) {
      if (!isClosed) {
        emit(
          const BleConnectionState.error("Не удалось установить соединение"),
        );
      }
    }
  }

  Future<void> _onDisconnect(
    DisconnectFromDevice event,
    Emitter<BleConnectionState> emit,
  ) async {
    _isManualDisconnect = true;
    _currentTargetAddress = null;
    _reconnectAttempts = 0;

    await _bleService.disconnect();

    if (!isClosed) {
      emit(const BleConnectionState.disconnected());
    }
  }

  void _onStatusUpdate(
    UpdateConnectionStatus event,
    Emitter<BleConnectionState> emit,
  ) {
    if (event.status == BluetoothConnectionState.connected &&
        _currentTargetAddress != null) {
      _reconnectAttempts = 0;
      emit(
        BleConnectionState.connected(
          deviceAddress: _currentTargetAddress!,
          deviceName: "Тренажер",
        ),
      );
    } else if (event.status == BluetoothConnectionState.disconnected) {
      if (!_isManualDisconnect &&
          _currentTargetAddress != null &&
          _reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;

        // ИСПРАВЛЕНО: Передаем текущую попытку реконнекта в стейт
        emit(
          BleConnectionState.connecting(
            _currentTargetAddress!,
            attempt: _reconnectAttempts,
          ),
        );

        add(RetryConnectionAfterDisconnect(_currentTargetAddress!));
      } else if (_isManualDisconnect ||
          _reconnectAttempts >= _maxReconnectAttempts) {
        _currentTargetAddress = null;
        _reconnectAttempts = 0;
        emit(const BleConnectionState.disconnected());
      }
    }
  }

  Future<void> _onRetryConnection(
    RetryConnectionAfterDisconnect event,
    Emitter<BleConnectionState> emit,
  ) async {
    // Если пользователь за время ожидания не нажал отмену и адрес совпадает
    if (_currentTargetAddress == event.address && !_isManualDisconnect) {
      try {
        await _bleService.connect(event.address);
      } catch (e) {
        // Ошибка перехватывается, чтобы не уронить поток BLoC.
        // Следующий вызов произойдет по событию disconnected из стрима, если лимит попыток не исчерпан.
      }
    }
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}
