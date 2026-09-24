// FILE: .\lib\core\ble_parsers\ble_parser.dart
import 'models/workout_data.dart';

enum EquipmentType { rower, treadmill, bike, stepper, unknown }

enum SmoothingMethod {
  none,
  simpleMovingAverage, // Метод А: SMA (Скользящее среднее)
  exponentialMovingAverage, // Метод Б: EMA (Экспоненциальное сглаживание)
}

class ParameterFilterConfig {
  final SmoothingMethod method;
  final int windowSize;
  final double alpha;

  const ParameterFilterConfig({
    required this.method,
    this.windowSize = 0,
    this.alpha = 1.0,
  });

  const ParameterFilterConfig.none()
    : method = SmoothingMethod.none,
      windowSize = 0,
      alpha = 1.0;
}

class SmoothingConfig {
  final bool enableSmoothing;
  final ParameterFilterConfig strokeRateConfig;
  final ParameterFilterConfig powerConfig;
  final ParameterFilterConfig paceConfig;
  final ParameterFilterConfig heartRateConfig;

  const SmoothingConfig({
    this.enableSmoothing = false,
    this.strokeRateConfig = const ParameterFilterConfig.none(),
    this.powerConfig = const ParameterFilterConfig.none(),
    this.paceConfig = const ParameterFilterConfig.none(),
    this.heartRateConfig = const ParameterFilterConfig.none(),
  });
}

abstract class BleParser {
  EquipmentType get type;
  SmoothingConfig get smoothingConfig;

  // ИЗМЕНЕНИЕ: Метод parse теперь возвращает строго WorkoutData
  WorkoutData parse(List<int> rawData, {int? iosHeartRate});
}
