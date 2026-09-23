enum EquipmentType { rower, treadmill, bike, stepper, unknown }

// ДОБАВЛЕНО: Доступные математические методы фильтрации данных
enum SmoothingMethod {
  none,
  simpleMovingAverage, // Метод А: SMA (Скользящее среднее)
  exponentialMovingAverage, // Метод Б: EMA (Экспоненциальное сглаживание)
}

// ДОБАВЛЕНО: Инкапсулированная конфигурация для конкретного спортивного параметра
class ParameterFilterConfig {
  final SmoothingMethod method;
  final int windowSize; // Для SMA: количество секунд/событий в окне
  final double
  alpha; // Для EMA: коэффициент значимости нового замера (0.0 - 1.0)

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

// ДОБАВЛЕНО: Общий класс настроек фильтрации, запрашиваемый от тренажера
class SmoothingConfig {
  final bool enableSmoothing;
  final ParameterFilterConfig strokeRateConfig; // Частота гребков (SPM)
  final ParameterFilterConfig powerConfig; // Мощность (Ватт)
  final ParameterFilterConfig paceConfig; // Темп / Скорость (Время на 500м)
  final ParameterFilterConfig heartRateConfig; // Пульс (BPM)

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
  Map<String, dynamic> parse(List<int> rawData, {int? iosHeartRate});
}
