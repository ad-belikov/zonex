import 'dart:collection';

import 'ble_parser.dart';

// ДОБАВЛЕНО: Сервис-процессор, выполняющий математическое сглаживание спортивных метрик на лету
class DataSmoother {
  final SmoothingConfig config;

  // Очереди для хранения истории значений (используются в алгоритме SMA)
  final ListQueue<double> _strokeRateQueue = ListQueue();
  final ListQueue<double> _powerQueue = ListQueue();
  final ListQueue<double> _paceQueue = ListQueue();

  // Предыдущие значения для рекуррентного расчета (используются в алгоритме EMA)
  double? _lastHeartRate;

  DataSmoother(this.config);

  /// Центральный метод сглаживания пакета данных
  Map<String, dynamic> smooth(Map<String, dynamic> parsedData) {
    if (!config.enableSmoothing || parsedData.containsKey('error')) {
      return parsedData;
    }

    final Map<String, dynamic> smoothedData = Map.from(parsedData);

    // 1. Сглаживание частоты гребков (Stroke Rate / SPM) -> SMA
    if (parsedData.containsKey('stroke_rate')) {
      smoothedData['stroke_rate'] = _processSma(
        parsedData['stroke_rate'] as double,
        _strokeRateQueue,
        config.strokeRateConfig,
      );
    }

    // 2. Сглаживание мощности (Power, Ватт) -> SMA
    if (parsedData.containsKey('power')) {
      smoothedData['power'] = _processSma(
        parsedData['power'] as double,
        _powerQueue,
        config.powerConfig,
      );
    }

    // 3. Сглаживание темпа (Pace, секунд на 500м) -> SMA
    if (parsedData.containsKey('pace')) {
      final double rawPace = (parsedData['pace'] as int).toDouble();
      smoothedData['pace'] = _processSma(
        rawPace,
        _paceQueue,
        config.paceConfig,
      ).round();
    }

    // 4. Сглаживание пульса (Heart Rate, ЧСС) -> EMA
    if (parsedData.containsKey('heart_rate')) {
      final double rawHr = (parsedData['heart_rate'] as int).toDouble();
      final double smoothedHr = _processEma(rawHr, config.heartRateConfig);
      smoothedData['heart_rate'] = smoothedHr.round();
    }

    return smoothedData;
  }

  /// Математическая реализация метода А: Simple Moving Average (SMA)
  double _processSma(
    double newValue,
    ListQueue<double> queue,
    ParameterFilterConfig pConfig,
  ) {
    if (pConfig.method != SmoothingMethod.simpleMovingAverage ||
        pConfig.windowSize <= 0) {
      return newValue;
    }

    // Добавляем новое значение в конец очереди
    queue.addLast(newValue);

    // Если размер очереди превысил заданное конфигурацией окно — удаляем старый замер
    if (queue.length > pConfig.windowSize) {
      queue.removeFirst();
    }

    // Вычисляем среднее арифметическое
    final double sum = queue.reduce((value, element) => value + element);
    return sum / queue.length;
  }

  /// Математическая реализация метода Б: Exponential Moving Average (EMA)
  /// Формула: Y_t = alpha * X_t + (1 - alpha) * Y_{t-1}
  double _processEma(double newValue, ParameterFilterConfig pConfig) {
    if (pConfig.method != SmoothingMethod.exponentialMovingAverage) {
      return newValue;
    }

    // Если это самый первый замер — инициализируем его как базовый без сглаживания
    if (_lastHeartRate == null) {
      _lastHeartRate = newValue;
      return newValue;
    }

    // Применяем формулу экспоненциального сглаживания
    final double alpha = pConfig.alpha;
    final double smoothedValue =
        (alpha * newValue) + ((1.0 - alpha) * _lastHeartRate!);

    _lastHeartRate = smoothedValue;
    return smoothedValue;
  }

  /// Сброс буферов (вызывается при старте новой сессии тренировки)
  void reset() {
    _strokeRateQueue.clear();
    _powerQueue.clear();
    _paceQueue.clear();
    _lastHeartRate = null;
  }
}
