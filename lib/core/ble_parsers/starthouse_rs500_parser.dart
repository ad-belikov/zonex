import 'dart:io';

import 'ble_parser.dart';

class StartHouseRS500Parser implements BleParser {
  @override
  EquipmentType get type => EquipmentType.rower;

  // ИСПРАВЛЕНО: Конфигурация заполнена на основе спецификаций Kinomap / FitShow и физиологии гребли
  @override
  SmoothingConfig get smoothingConfig => const SmoothingConfig(
    enableSmoothing: true,
    // Метод А: SMA с временным окном 10 сек для стабилизации частоты гребков
    strokeRateConfig: ParameterFilterConfig(
      method: SmoothingMethod.simpleMovingAverage,
      windowSize: 10,
    ),
    // Метод А: SMA с окном 4 сек для полного сглаживания нулей в фазе расслабления (возврата)
    powerConfig: ParameterFilterConfig(
      method: SmoothingMethod.simpleMovingAverage,
      windowSize: 4,
    ),
    // Метод А: SMA с окном 4 сек для плавной и красивой индикации темпа на дисплее
    paceConfig: ParameterFilterConfig(
      method: SmoothingMethod.simpleMovingAverage,
      windowSize: 4,
    ),
    // Метод Б: EMA с коэффициентом alpha = 0.25 (усреднение ~4-5 сек при 1 Гц) для гашения сбоев датчиков 5 кГц
    heartRateConfig: ParameterFilterConfig(
      method: SmoothingMethod.exponentialMovingAverage,
      alpha: 0.25,
    ),
  );

  @override
  Map<String, dynamic> parse(List<int> rawData, {int? iosHeartRate}) {
    if (rawData.isEmpty) return {};

    try {
      final double strokeRate = rawData.length > 2 ? rawData[2] * 0.5 : 0.0;

      final int strokeCount = rawData.length > 4
          ? (rawData[3] << 8) | rawData[4]
          : 0;

      final int distance = rawData.length > 7
          ? (rawData[5] << 16) | (rawData[6] << 8) | rawData[7]
          : 0;

      final int pace = rawData.length > 9 ? (rawData[8] << 8) | rawData[9] : 0;

      double power = 0.0;
      if (rawData.length > 11) {
        int rawPower = (rawData[10] << 8) | rawData[11];
        if (rawPower > 32767) {
          rawPower -= 65536;
        }
        power = rawPower.toDouble();
      }

      int finalHeartRate = 0;
      if (rawData.length > 12) {
        final int ftmsHeartRate = rawData[12];
        finalHeartRate = Platform.isIOS && iosHeartRate != null
            ? iosHeartRate
            : ftmsHeartRate;
      } else if (iosHeartRate != null) {
        finalHeartRate = iosHeartRate;
      }

      return {
        'equipment': 'StartHouse RS 500',
        'stroke_rate': strokeRate,
        'stroke_count': strokeCount,
        'distance': distance.toDouble(),
        'pace': pace,
        'power': power,
        'heart_rate': finalHeartRate,
      };
    } catch (e) {
      return {'error': 'Parsing failed: $e'};
    }
  }
}
