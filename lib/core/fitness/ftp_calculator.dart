// FILE: lib/core/fitness/ftp_calculator.dart
import 'dart:math' as math;

import '../preferences/preferences_service.dart';

class FtpCalculator {
  final PreferencesService _preferencesService;

  // Хранилище посекундной мощности за текущую сессию
  final List<double> _powerHistory = [];

  // Для 20-минутного теста нам нужно 20 минут * 60 секунд = 1200 точек данных.
  // Если сессия короче (например, идет калибровка), берем максимум из доступного,
  // но спортивно валидный результат считается при заездах от 5-20 минут.
  static const int _targetWindowSeconds = 1200;

  FtpCalculator(this._preferencesService);

  /// Добавить новую точку мощности из BLE пакета тренажера (вызывается раз в секунду)
  void addPowerSample(double watts) {
    if (watts < 0) return;
    _powerHistory.add(watts);
  }

  /// Сбросить историю текущего заезда
  void resetSession() {
    _powerHistory.clear();
  }

  /// Возвращает текущее исторически сохраненное значение FTP пользователя
  double getStoredFtp() {
    // Расширим PreferencesService чуть позже, добавив туда ключ
    return _preferencesService.getFtpValue();
  }

  /// Рассчитывает FTP за текущую сессию на основе пикового интервала
  double calculateCurrentSessionFtp() {
    if (_powerHistory.isEmpty) return getStoredFtp();

    final int totalSeconds = _powerHistory.length;
    double maxWindowAverage = 0.0;

    if (totalSeconds <= _targetWindowSeconds) {
      // Если заезд короче 20 минут, считаем среднее за весь текущий заезд
      final double sum = _powerHistory.reduce((a, b) => a + b);
      maxWindowAverage = sum / totalSeconds;
    } else {
      // Используем алгоритм скользящего окна для поиска самого эффективного 20-минутного отрезка
      double currentWindowSum = 0.0;

      // Инициализируем первое окно
      for (int i = 0; i < _targetWindowSeconds; i++) {
        currentWindowSum += _powerHistory[i];
      }
      maxWindowAverage = currentWindowSum / _targetWindowSeconds;

      // Сдвигаем окно по всей истории
      double runningSum = currentWindowSum;
      for (int i = _targetWindowSeconds; i < totalSeconds; i++) {
        runningSum =
            runningSum -
            _powerHistory[i - _targetWindowSeconds] +
            _powerHistory[i];
        final double currentAverage = runningSum / _targetWindowSeconds;
        maxWindowAverage = math.max(maxWindowAverage, currentAverage);
      }
    }

    // Классическая спортивная формула: 95% от пиковой 20-минутной мощности
    final double calculatedFtp = maxWindowAverage * 0.95;

    // Если новый результат выше текущего сохраненного, обновляем его на устройстве
    final double currentStored = getStoredFtp();
    if (calculatedFtp > currentStored && totalSeconds >= 300) {
      // Сохраняем, только если тест длился хотя бы 5 минут для защиты от случайных пиков
      _preferencesService.saveFtpValue(calculatedFtp);
    }

    return calculatedFtp;
  }
}
