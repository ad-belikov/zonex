// FILE: .\lib\core\ble_parsers\ftms\bike_ftms_parser.dart
import 'dart:typed_data';

import '../models/workout_data.dart';
import 'ftms_sub_parser.dart';

class BikeFtmsParser implements FtmsSubParser {
  final double userWeightKg;

  BikeFtmsParser({this.userWeightKg = 75.0});

  @override
  WorkoutData parse(
    ByteData buffer,
    int length,
    int? iosHeartRate,
    String deviceName,
  ) {
    if (length < 2) {
      return const WorkoutData.error('Пакет Bike слишком короткий');
    }

    final int flags = buffer.getUint16(0, Endian.little);
    int offset = 2;

    double speed = 0.0;
    if ((flags & 0x0001) == 0) {
      if (offset + 2 > length) {
        return const WorkoutData.error('Поврежден пакет скорости');
      }
      speed = buffer.getUint16(offset, Endian.little) * 0.01;
      offset += 2;
    }

    double cadence = 0.0;
    if ((flags & 0x0002) != 0) {
      if (offset + 2 > length) {
        return const WorkoutData.error('Поврежден пакет каденса');
      }
      cadence = buffer.getUint16(offset, Endian.little) * 0.5;
      offset += 2;
    }

    double distance = 0.0;
    if ((flags & 0x0004) != 0) {
      if (offset + 3 > length) {
        return const WorkoutData.error('Поврежден пакет дистанции');
      }
      distance =
          (buffer.getUint8(offset + 2) << 16 |
                  buffer.getUint8(offset + 1) << 8 |
                  buffer.getUint8(offset))
              .toDouble();
      offset += 3;
    }

    int resistanceLevel = 0;
    if ((flags & 0x0008) != 0) {
      if (offset + 2 > length) {
        return const WorkoutData.error('Поврежден пакет сопротивления');
      }
      resistanceLevel = buffer.getInt16(offset, Endian.little);
      offset += 2;
    }

    double power = 0.0;
    if ((flags & 0x0010) != 0) {
      if (offset + 2 > length) {
        return const WorkoutData.error('Поврежден пакет мощности');
      }
      power = buffer.getInt16(offset, Endian.little).toDouble();
      offset += 2;
    }

    int heartRate = 0;
    if ((flags & 0x0200) != 0) {
      if (offset + 1 <= length) {
        heartRate = buffer.getUint8(offset);
      }
    }

    final double wattsPerKg = userWeightKg > 0 ? (power / userWeightKg) : 0.0;

    return WorkoutData(
      equipmentName: '$deviceName (Bike)',
      heartRate: iosHeartRate ?? heartRate,
      distance: distance,
      duration: 0,
      energy: 0.0,
      speed: speed,
      cadence: cadence,
      bikePower: power,
      wattsPerKg: wattsPerKg,
      resistanceLevel: resistanceLevel,
    );
  }
}
