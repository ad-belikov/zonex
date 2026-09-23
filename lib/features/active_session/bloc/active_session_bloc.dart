import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ble_parsers/ble_parser.dart';
import '../../../core/ble_parsers/ble_parser_factory.dart';
import '../../../core/ble_parsers/data_smoother.dart';
import '../../../core/ble_service/ble_service.dart';
import 'active_session_event.dart';
import 'active_session_state.dart';

// ДОБАВЛЕНО: Блок управления состоянием активной тренировки с математической фильтрацией метрик
class ActiveSessionBloc extends Bloc<ActiveSessionEvent, ActiveSessionState> {
  final BleService _bleService;
  StreamSubscription<List<int>>? _rawDataSubscription;

  BleParser? _currentParser;
  DataSmoother? _smoother;

  ActiveSessionBloc(this._bleService) : super(ActiveSessionInitial()) {
    on<StartSession>(_onStartSession);
    on<UpdateRawData>(_onUpdateRawData);
    on<StopSession>(_onStopSession);
  }

  Future<void> _onStartSession(
    StartSession event,
    Emitter<ActiveSessionState> emit,
  ) async {
    await _rawDataSubscription?.cancel();

    // Пытаемся получить парсер под конкретное устройство (через UUID или имя)
    // Передаем пустые структуры для базовой инициализации фабрики под FTMS
    _currentParser = BleParserFactory.getParser(
      event.deviceName,
      {},
      ['1826'], // Принудительно передаем UUID FTMS для StartHouse RS 500
    );

    if (_currentParser != null) {
      // Инициализируем наш математический сглаживатель конфигурацией этого парсера
      _smoother = DataSmoother(_currentParser!.smoothingConfig);
      _smoother?.reset();
    }

    // Подписываемся на поток сырых данных из BLE-сервиса
    _rawDataSubscription = _bleService.rawDataStream.listen((bytes) {
      if (!isClosed) add(UpdateRawData(bytes));
    });

    // Выставляем начальное пустое состояние тренировки
    emit(
      ActiveSessionData(
        strokeRate: 0.0,
        strokeCount: 0,
        distance: 0.0,
        power: 0.0,
        heartRate: 0,
        formattedPace: '0:00',
      ),
    );
  }

  void _onUpdateRawData(UpdateRawData event, Emitter<ActiveSessionState> emit) {
    if (_currentParser == null || _smoother == null) return;

    // 1. Десериализация сырых байт в карту параметров
    final Map<String, dynamic> rawParsed = _currentParser!.parse(event.rawData);

    // 2. Пропуск через алгоритмы SMA и EMA сглаживания
    final Map<String, dynamic> smoothed = _smoother!.smooth(rawParsed);

    if (smoothed.containsKey('error')) return;

    // 3. Извлечение очищенных метрик
    final double strokeRate = (smoothed['stroke_rate'] ?? 0.0) as double;
    final int strokeCount = (smoothed['stroke_count'] ?? 0) as int;
    final double distance = (smoothed['distance'] ?? 0.0) as double;
    final double power = (smoothed['power'] ?? 0.0) as double;
    final int heartRate = (smoothed['heart_rate'] ?? 0) as int;
    final int paceSeconds = (smoothed['pace'] ?? 0) as int;

    // 4. ДОБАВЛЕНО: Конвертация темпа из секунд (например, 135) в формат ММ:СС (например, "2:15")
    final String formattedPace = _formatPace(paceSeconds);

    // 5. Отправка чистого состояния на UI
    emit(
      ActiveSessionData(
        strokeRate: strokeRate,
        strokeCount: strokeCount,
        distance: distance,
        power: power,
        heartRate: heartRate,
        formattedPace: formattedPace,
      ),
    );
  }

  Future<void> _onStopSession(
    StopSession event,
    Emitter<ActiveSessionState> emit,
  ) async {
    await _rawDataSubscription?.cancel();
    _smoother?.reset();
    emit(ActiveSessionFinished());
  }

  // ДОБАВЛЕНО: Вспомогательная утилита форматирования времени на 500 метров
  String _formatPace(int totalSeconds) {
    if (totalSeconds <= 0 || totalSeconds > 3600) return '0:00';
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String secondsStr = seconds < 10 ? '0$seconds' : '$seconds';
    return '$minutes:$secondsStr';
  }

  @override
  Future<void> close() {
    _rawDataSubscription?.cancel();
    _smoother?.reset();
    return super.close();
  }
}
