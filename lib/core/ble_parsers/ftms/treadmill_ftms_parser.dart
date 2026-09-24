// FILE: .\lib\core\ble_parsers\ftms\treadmill_ftms_parser.dart
import 'dart:typed_data';

import '../models/workout_data.dart';
import 'ftms_sub_parser.dart';

class TreadmillFtmsParser implements FtmsSubParser {
  @override
  WorkoutData parse(
    ByteData buffer,
    int length,
    int? iosHeartRate,
    String deviceName,
  ) {
    if (length < 2) {
      return const WorkoutData.error('Пакет Treadmill слишком короткий');
    }

    final int flags = buffer.getUint16(0, Endian.little);
    int offset = 2;

    double speed = 0.0;
    if ((flags & 0x0001) == 0) {
      if (offset + 2 > length) {
        return const WorkoutData.error('Поврежден пакет скорости');
      }
      speed = buffer.getUint16(offset, Endian.little) * 0.1;
      offset += 2;
    }

    double incline = 0.0;
    if ((flags & 0x0004) != 0) {
      if (offset + 2 > length) {
        return const WorkoutData.error('Поврежден пакет наклона');
      }
      incline = buffer.getInt16(offset, Endian.little) * 0.1;
      offset += 2;
    }

    double distance = 0.0;
    if ((flags & 0x0010) != 0) {
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

    final int paceSeconds = speed > 0.5 ? (3600 / speed).round() : 0;

    double runCadence = 0.0;
    if ((flags & 0x0040) != 0) {
      if (offset + 1 > length) {
        return const WorkoutData.error('Поврежден пакет каденса');
      }
      runCadence = buffer.getUint8(offset).toDouble() * 2;
      offset += 1;
    }

    double contactTime = 0.0;
    if ((flags & 0x0080) != 0) {
      if (offset + 1 > length) {
        return const WorkoutData.error('Поврежден пакет времени контакта');
      }
      contactTime = buffer.getUint8(offset).toDouble() * 5;
      offset += 1;
    }

    int heartRate = 0;
    if ((flags & 0x0200) != 0) {
      if (offset + 1 <= length) {
        heartRate = buffer.getUint8(offset);
      }
    }

    return WorkoutData(
      equipmentName: '$deviceName (Treadmill)',
      heartRate: iosHeartRate ?? heartRate,
      distance: distance,
      duration: 0,
      energy: 0.0,
      speed: speed,
      runPaceSeconds: paceSeconds,
      runCadence: runCadence,
      incline: incline,
      contactTime: contactTime,
    );
  }
}
