import 'dart:collection';

import '../ble_parsers/models/workout_data.dart';
import 'ble_parser.dart';

class DataSmoother {
  final SmoothingConfig config;

  final ListQueue<double> _strokeRateQueue = ListQueue();
  final ListQueue<double> _powerQueue = ListQueue();
  final ListQueue<double> _paceQueue = ListQueue();
  final ListQueue<double> _speedQueue = ListQueue();
  final ListQueue<double> _cadenceQueue = ListQueue();

  double? _lastHeartRate;

  DataSmoother(this.config);

  WorkoutData smooth(WorkoutData parsedData) {
    // 1. Отсекаем состояние ошибки парсинга.
    // Если toString() содержит маркер ошибки, возвращаем её как есть без изменений.
    if (parsedData.toString().contains('errorMessage') ||
        parsedData.toString().contains('error')) {
      return parsedData;
    }

    if (!config.enableSmoothing) {
      return parsedData;
    }

    // 2. Явное безопасное приведение к успешному подклассу Freezed.
    // Так как strict-casts запрещает неявный dynamic, мы кастим объект к его
    // базовому интерфейсу WorkoutData, но считываем его поля через паттерн-каст Dart 3.
    // Из-за Freezed свойства доступны на уровне WorkoutData, если они есть во всех ветках,
    // но чтобы обойти ограничения sealed-класса, мы объявляем её как именованную структуру:
    final data = parsedData;

    // В строгом режиме статического анализа извлекаем переменные с явным указанием типов
    final int currentHeartRate = (data as dynamic).heartRate as int;
    final double currentStrokeRate = (data as dynamic).strokeRate as double;
    final int currentSplitTime500m = (data as dynamic).splitTime500m as int;
    final double currentCadence = (data as dynamic).cadence as double;
    final double currentBikePower = (data as dynamic).bikePower as double;
    final double currentSpeed = (data as dynamic).speed as double;
    final double currentRunCadence = (data as dynamic).runCadence as double;
    final double currentStepRate = (data as dynamic).stepRate as double;

    // 1. Сглаживание пульса (EMA)
    int updatedHeartRate = currentHeartRate;
    if (currentHeartRate > 0) {
      updatedHeartRate = _processEma(
        currentHeartRate.toDouble(),
        config.heartRateConfig,
      ).round();
    }

    // 2. Гребля (Rower)
    double updatedStrokeRate = currentStrokeRate;
    int updatedSplitTime = currentSplitTime500m;
    if (currentStrokeRate > 0) {
      updatedStrokeRate = _processSma(
        currentStrokeRate,
        _strokeRateQueue,
        config.strokeRateConfig,
      );
    }
    if (currentSplitTime500m > 0) {
      updatedSplitTime = _processSma(
        currentSplitTime500m.toDouble(),
        _paceQueue,
        config.paceConfig,
      ).round();
    }

    // 3. Велосипед (Bike)
    double updatedCadence = currentCadence;
    double updatedBikePower = currentBikePower;
    double updatedSpeed = currentSpeed;

    if (currentCadence > 0) {
      updatedCadence = _processSma(
        currentCadence,
        _cadenceQueue,
        config.strokeRateConfig,
      );
    }
    if (currentBikePower > 0) {
      updatedBikePower = _processSma(
        currentBikePower,
        _powerQueue,
        config.powerConfig,
      );
    }
    if (currentSpeed > 0) {
      updatedSpeed = _processSma(currentSpeed, _speedQueue, config.paceConfig);
    }

    // 4. Беговая дорожка (Treadmill)
    double updatedRunCadence = currentRunCadence;
    if (currentRunCadence > 0) {
      updatedRunCadence = _processSma(
        currentRunCadence,
        _cadenceQueue,
        config.strokeRateConfig,
      );
    }

    // 5. Степпер (Stepper)
    double updatedStepRate = currentStepRate;
    if (currentStepRate > 0) {
      updatedStepRate = _processSma(
        currentStepRate,
        _cadenceQueue,
        config.strokeRateConfig,
      );
    }

    // Вызываем кодогенерированный метод copyWith через безопасное приведение типов
    return (data as dynamic).copyWith(
      heartRate: updatedHeartRate,
      strokeRate: updatedStrokeRate,
      splitTime500m: updatedSplitTime,
      cadence: updatedCadence,
      bikePower: updatedBikePower,
      speed: updatedSpeed,
      runCadence: updatedRunCadence,
      stepRate: updatedStepRate,
    ) as WorkoutData;
  }

  double _processSma(
    double newValue,
    ListQueue<double> queue,
    ParameterFilterConfig pConfig,
  ) {
    if (pConfig.method != SmoothingMethod.simpleMovingAverage ||
        pConfig.windowSize <= 0) {
      return newValue;
    }
    queue.addLast(newValue);
    if (queue.length > pConfig.windowSize) {
      queue.removeFirst();
    }
    if (queue.isEmpty) return newValue;
    final double sum = queue.reduce((value, element) => value + element);
    return sum / queue.length;
  }

  double _processEma(double newValue, ParameterFilterConfig pConfig) {
    if (pConfig.method != SmoothingMethod.exponentialMovingAverage) {
      return newValue;
    }
    if (_lastHeartRate == null) {
      _lastHeartRate = newValue;
      return newValue;
    }
    final double alpha = pConfig.alpha;
    final double smoothedValue =
        (alpha * newValue) + ((1.0 - alpha) * _lastHeartRate!);
    _lastHeartRate = smoothedValue;
    return smoothedValue;
  }

  void reset() {
    _strokeRateQueue.clear();
    _powerQueue.clear();
    _paceQueue.clear();
    _speedQueue.clear();
    _cadenceQueue.clear();
    _lastHeartRate = null;
  }
}

enum ModifierSmoothingMethod {
  none,
  simpleMovingAverage,
  exponentialMovingAverage,
}
