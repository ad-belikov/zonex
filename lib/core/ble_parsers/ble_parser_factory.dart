// FILE: .\lib\core\ble_parsers\ble_parser_factory.dart
import 'ble_parser.dart';
import 'ftms_universal_parser.dart';
import 'starthouse_rs500_parser.dart';

class BleParserFactory {
  static BleParser? getParser(
    String? localName,
    Map<int, List<int>> manufacturerData,
    List<String> serviceUuids, {
    String targetCharacteristicUuid = '',
  }) {
    final name = localName ?? '';

    // 1. Кастомное оборудование
    if (name.contains('StartHouse RS 500')) {
      return StartHouseRS500Parser();
    }

    // 2. Универсальные UUID характеристик FTMS стандартов
    final String targetUuid = targetCharacteristicUuid.toLowerCase();
    final bool hasFtmsService = serviceUuids.any(
      (uuid) => uuid.toLowerCase().contains('1826'),
    );

    final isTreadmill = targetUuid.contains('2acd');
    final isBike = targetUuid.contains('2ad2');
    final isRower = targetUuid.contains('2ad1');
    final isStepper =
        targetUuid.contains('2acf') || targetUuid.contains('2ad0');

    if (hasFtmsService || isTreadmill || isBike || isRower || isStepper) {
      // Авто-фоллбек UUID, если из UI не прокинут точный инстанс
      String effectiveUuid = targetUuid;
      if (effectiveUuid.isEmpty) {
        if (name.contains('Bike') || name.contains('Cycle')) {
          effectiveUuid = '2ad2';
        } else if (name.contains('Run') || name.contains('Treadmill')) {
          effectiveUuid = '2acd';
        } else if (name.contains('Row')) {
          effectiveUuid = '2ad1';
        } else {
          effectiveUuid = '2acf';
        }
      }

      return FtmsUniversalParser(
        characteristicUuid: effectiveUuid,
        deviceName: name.isNotEmpty ? name : 'Спортивный тренажер',
      );
    }

    return null;
  }
}
