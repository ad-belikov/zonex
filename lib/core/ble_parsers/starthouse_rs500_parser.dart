// FILE: .\lib\core\ble_parsers\starthouse_rs500_parser.dart
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

import '../ble_parsers/models/workout_data.dart';
import 'ble_parser.dart';

class StartHouseRS500Parser implements BleParser {
  @override
  EquipmentType get type => EquipmentType.rower;

  @override
  SmoothingConfig get smoothingConfig => const SmoothingConfig(
    enableSmoothing: true,
    strokeRateConfig: ParameterFilterConfig(
      method: SmoothingMethod.simpleMovingAverage,
      windowSize: 10,
    ),
    powerConfig: ParameterFilterConfig(
      method: SmoothingMethod.simpleMovingAverage,
      windowSize: 4,
    ),
    paceConfig: ParameterFilterConfig(
      method: SmoothingMethod.simpleMovingAverage,
      windowSize: 4,
    ),
    heartRateConfig: ParameterFilterConfig(
      method: SmoothingMethod.exponentialMovingAverage,
      alpha: 0.25,
    ),
  );

  @override
  WorkoutData parse(List<int> rawData, {int? iosHeartRate}) {
    if (rawData.isEmpty || rawData.length < 13) {
      return const WorkoutData.error(
        'Критическая ошибка: Пакет данных кастомного гребца усечен.',
      );
    }

    try {
      final Uint8List bytes = Uint8List.fromList(rawData);
      final ByteData buffer = ByteData.sublistView(bytes);

      final double strokeRate = (buffer.getUint8(2) & 0xFF) * 0.5;
      final int strokeCount = buffer.getUint16(3);
      final int distance =
          (buffer.getUint8(5) << 16) |
          (buffer.getUint8(6) << 8) |
          buffer.getUint8(7);
      final int pace = buffer.getUint16(8);

      final int rawPower = buffer.getInt16(10);
      final double power = (rawPower < 0 || rawPower > 3000)
          ? 0.0
          : rawPower.toDouble();

      int finalHeartRate = buffer.getUint8(12) & 0xFF;

      // ИСПРАВЛЕНО: Вместо обращения к Platform (которое падает в изолятах)
      // используем безопасный для веб/изолятов kIsWeb / defaultTargetPlatform.
      final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
      if (isIOS && iosHeartRate != null) {
        finalHeartRate = iosHeartRate;
      }

      if (finalHeartRate < 30 || finalHeartRate > 240) {
        finalHeartRate = 0;
      }

      return WorkoutData(
        equipmentName: 'StartHouse RS 500',
        heartRate: finalHeartRate,
        distance: distance.toDouble(),
        duration: 0,
        energy: 0.0,
        strokeRate: strokeRate,
        strokeCount: strokeCount,
        splitTime500m: pace,
        bikePower: power,
      );
    } catch (e) {
      return WorkoutData.error('Исключение парсинга буфера StartHouse: $e');
    }
  }
}
