// FILE: .\lib\core\ble_parsers\ftms_universal_parser.dart
import 'dart:typed_data';

import 'ble_parser.dart';
import 'ftms/bike_ftms_parser.dart';
import 'ftms/ftms_sub_parser.dart';
import 'ftms/rower_ftms_parser.dart';
import 'ftms/stepper_ftms_parser.dart';
import 'ftms/treadmill_ftms_parser.dart';
import 'models/workout_data.dart';

class FtmsUniversalParser implements BleParser {
  final String _characteristicUuid;
  final String _deviceName;
  final Map<EquipmentType, FtmsSubParser> _parsers;

  FtmsUniversalParser({
    required String characteristicUuid,
    String deviceName = 'FTMS Machine',
    double userWeightKg = 75.0,
  }) : _characteristicUuid = characteristicUuid.toLowerCase(),
       _deviceName = deviceName.isNotEmpty ? deviceName : 'FTMS Machine',
       _parsers = {
         EquipmentType.treadmill: TreadmillFtmsParser(),
         EquipmentType.bike: BikeFtmsParser(userWeightKg: userWeightKg),
         EquipmentType.rower: RowerFtmsParser(),
         EquipmentType.stepper: StepperFtmsParser(),
       };

  @override
  EquipmentType get type {
    if (_characteristicUuid.contains('2acd')) return EquipmentType.treadmill;
    if (_characteristicUuid.contains('2ad2')) return EquipmentType.bike;
    if (_characteristicUuid.contains('2ad1')) return EquipmentType.rower;
    if (_characteristicUuid.contains('2acf') ||
        _characteristicUuid.contains('2ad0')) {
      return EquipmentType.stepper;
    }
    return EquipmentType.unknown;
  }

  @override
  SmoothingConfig get smoothingConfig => const SmoothingConfig(
    enableSmoothing: true,
    powerConfig: ParameterFilterConfig(
      method: SmoothingMethod.simpleMovingAverage,
      windowSize: 4,
    ),
    heartRateConfig: ParameterFilterConfig(
      method: SmoothingMethod.exponentialMovingAverage,
      alpha: 0.2,
    ),
  );

  @override
  WorkoutData parse(List<int> rawData, {int? iosHeartRate}) {
    if (rawData.isEmpty || rawData.length < 3) {
      return const WorkoutData.error('Пакет FTMS пуст или поврежден');
    }

    final Uint8List bytes = Uint8List.fromList(rawData);
    final ByteData buffer = ByteData.sublistView(bytes);
    final int length = bytes.length;

    try {
      final subParser = _parsers[type];
      if (subParser != null) {
        return subParser.parse(buffer, length, iosHeartRate, _deviceName);
      }
      return const WorkoutData.error(
        'Неизвестный тип UUID характеристики FTMS',
      );
    } catch (e) {
      return WorkoutData.error('Исключение при разборе FTMS структуры: $e');
    }
  }
}
