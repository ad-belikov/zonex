// FILE: lib/features/active_session/bloc/active_session_bloc.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:rxdart/rxdart.dart';

// Импорты ядра системы
import '../../../core/background/background_handler.dart';
import '../../../core/ble_parsers/ble_parser.dart';
import '../../../core/ble_parsers/ble_parser_factory.dart';
import '../../../core/ble_parsers/data_smoother.dart';
import '../../../core/ble_parsers/models/workout_data.dart';
import '../../../core/ble_service/ble_service.dart';
import '../../../core/fitness/ftp_calculator.dart'; // Добавлено
// Импорты текущей фичи
import 'active_session_event.dart';
import 'active_session_state.dart';

class ActiveSessionBloc extends Bloc<ActiveSessionEvent, ActiveSessionState> {
  final BleService _bleService;
  final FtpCalculator
  _ftpCalculator; // Зависимость передается через конструктор

  StreamSubscription<List<int>>? _rawDataSubscription;
  DataSmoother? _smoother;
  BleParser? _currentParser;

  ActiveSessionBloc(this._bleService, this._ftpCalculator)
    : super(const ActiveSessionState.initial()) {
    _initForegroundTask(); // Теперь метод гарантированно определен ниже!
    on<StartSession>(_onStartSession);
    on<UpdateRawData>(_onUpdateRawData);
    on<StopSession>(_onStopSession);
  }

  /// ИСПРАВЛЕНО: Метод инициализации фонового режима возвращен в тело класса
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'zonex_workout_channel',
        channelName: 'ZonEx Тренировка',
        channelDescription: 'Показывает статус активной тренировки в фоне.',
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
      ),
    );
  }

  Future<void> _startForegroundService(String deviceName) async {
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      // Рекомендация по оптимизации батареи
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'ZonEx: Активная тренировка',
      notificationText: 'Подключено к тренажеру: $deviceName',
      callback: startCallback,
    );
  }

  Future<void> _stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  String _resolveFtmsCharacteristicUuid(String deviceName) {
    final name = deviceName.toLowerCase();
    if (name.contains('treadmill') ||
        name.contains('run') ||
        name.contains('track')) {
      return '2acd';
    } else if (name.contains('row') || name.contains('rower')) {
      return '2ad1';
    } else if (name.contains('step') ||
        name.contains('stair') ||
        name.contains('climber')) {
      return '2acf';
    }
    return '2ad2';
  }

  Future<void> _onStartSession(
    StartSession event,
    Emitter<ActiveSessionState> emit,
  ) async {
    await _rawDataSubscription?.cancel();
    _rawDataSubscription = null;

    // Сбрасываем старый заезд в калькуляторе при старте новой тренировки
    _ftpCalculator.resetSession();

    _currentParser = BleParserFactory.getParser(
      event.deviceName,
      {},
      ['1826'],
      targetCharacteristicUuid: _resolveFtmsCharacteristicUuid(
        event.deviceName,
      ),
    );

    if (_currentParser != null) {
      _smoother = DataSmoother(_currentParser!.smoothingConfig);
      _smoother?.reset();
    }

    await _startForegroundService(event.deviceName);

    _rawDataSubscription = _bleService.rawDataStream
        .throttleTime(const Duration(milliseconds: 1000), trailing: true)
        .listen((bytes) {
          if (!isClosed) add(UpdateRawData(bytes));
        });

    emit(
      ActiveSessionState.data(
        equipmentType: _currentParser?.type ?? EquipmentType.unknown,
        equipmentName: event.deviceName,
      ),
    );
  }

  void _onUpdateRawData(UpdateRawData event, Emitter<ActiveSessionState> emit) {
    if (_currentParser == null ||
        _smoother == null ||
        isClosed ||
        emit.isDone) {
      return;
    }

    try {
      final WorkoutData parsedWorkoutData = _currentParser!.parse(
        event.rawData,
      );
      final WorkoutData smoothed = _smoother!.smooth(parsedWorkoutData);

      // ИСПРАВЛЕНО: Вместо хрупкого switch-case по скрытым подклассам Freezed,
      // мы проверяем состояние ошибки через строку toString(). Это на 100% совместимо
      // с любой версией Freezed и компилируется в строгом режиме strict-casts.
      final String dataString = smoothed.toString();
      final bool isError =
          dataString.contains('errorMessage') || dataString.contains('error');

      if (isError) {
        // Извлекаем сообщение об ошибке, если это необходимо для дебага
        debugPrint('🚨 Ошибка структуры данных BLE пакета');
        return;
      }

      if (emit.isDone) return;

      // Логируем мощность в калькулятор FTP, если это байк
      // Приводим к dynamic, чтобы обойти ограничения sealed-интерфейса в строгом режиме
      final dynamic data = smoothed;
      final double bikePowerValue = (data.bikePower as num).toDouble();

      if (_currentParser!.type == EquipmentType.bike && bikePowerValue > 0) {
        _ftpCalculator.addPowerSample(bikePowerValue);
      }

      // Принудительно вызываем расчет (обновит SharedPreferences, если тест пройден)
      _ftpCalculator.calculateCurrentSessionFtp();

      final double distanceValue = (data.distance as num).toDouble();
      final int heartRateValue = data.heartRate as int;

      String updateText = 'Дистанция: ${distanceValue.round()}м';
      if (heartRateValue > 0) {
        updateText += ' | Пульс: $heartRateValue BPM';
      }
      FlutterForegroundTask.updateService(notificationText: updateText);

      // Распределяем метрики по типам тренажеров для UI
      switch (_currentParser!.type) {
        case EquipmentType.rower:
          emit(
            ActiveSessionState.data(
              equipmentType: EquipmentType.rower,
              equipmentName: data.equipmentName as String,
              heartRate: heartRateValue,
              distance: distanceValue,
              strokeRate: (data.strokeRate as num).toDouble(),
              strokeCount: data.strokeCount as int,
              rowerPower: bikePowerValue,
              formattedPace: _formatPace(data.splitTime500m as int),
            ),
          );
          break;
        case EquipmentType.bike:
          emit(
            ActiveSessionState.data(
              equipmentType: EquipmentType.bike,
              equipmentName: data.equipmentName as String,
              heartRate: heartRateValue,
              distance: distanceValue,
              bikeSpeed: (data.speed as num).toDouble(),
              bikeCadence: (data.cadence as num).toDouble(),
              bikePower: bikePowerValue,
              resistanceLevel: data.resistanceLevel as int,
            ),
          );
          break;
        case EquipmentType.treadmill:
          emit(
            ActiveSessionState.data(
              equipmentType: EquipmentType.treadmill,
              equipmentName: data.equipmentName as String,
              heartRate: heartRateValue,
              distance: distanceValue,
              runSpeed: (data.speed as num).toDouble(),
              runPace: _formatPace(data.runPaceSeconds as int),
              runCadence: (data.runCadence as num).toDouble(),
              incline: (data.incline as num).toDouble(),
            ),
          );
          break;
        case EquipmentType.stepper:
          emit(
            ActiveSessionState.data(
              equipmentType: EquipmentType.stepper,
              equipmentName: data.equipmentName as String,
              heartRate: heartRateValue,
              distance: distanceValue,
              floorsCount: data.floorsCount as int,
              stepRate: (data.stepRate as num).toDouble(),
            ),
          );
          break;
        case EquipmentType.unknown:
          break;
      }
    } catch (e) {
      debugPrint('🚨 Ошибка в потоке обработки данных BLoC: $e');
    }
  }

  Future<void> _onStopSession(
    StopSession event,
    Emitter<ActiveSessionState> emit,
  ) async {
    await _rawDataSubscription?.cancel();
    _rawDataSubscription = null;
    _smoother?.reset();

    _ftpCalculator.calculateCurrentSessionFtp();

    await _stopForegroundService();

    if (!isClosed && !emit.isDone) {
      emit(const ActiveSessionState.finished());
    }
  }

  String _formatPace(int totalSeconds) {
    if (totalSeconds <= 0 || totalSeconds > 3600) return '0:00';
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> close() async {
    await _rawDataSubscription?.cancel();
    _rawDataSubscription = null;
    _smoother?.reset();
    await _stopForegroundService();
    return super.close();
  }
}
