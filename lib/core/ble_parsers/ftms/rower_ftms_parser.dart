// FILE: .\lib\core\ble_parsers\ftms\rower_ftms_parser.dart
import 'dart:typed_data';

import '../models/workout_data.dart';
import 'ftms_sub_parser.dart';

class RowerFtmsParser implements FtmsSubParser {
  @override
  WorkoutData parse(
    ByteData buffer,
    int length,
    int? iosHeartRate,
    String deviceName,
  ) {
    if (length < 2) {
      return const WorkoutData.error('Пакет Rower слишком короткий');
    }

    final int flags = buffer.getUint16(0, Endian.little);
    int offset = 2;

    double strokeRate = 0.0;
    if ((flags & 0x0001) == 0) {
      if (offset + 1 > length) {
        return const WorkoutData.error('Поврежден пакет темпа гребков');
      }
      strokeRate = buffer.getUint8(offset) * 0.5;
      offset += 1;
    }

    int strokeCount = 0;
    if ((flags & 0x0002) != 0) {
      if (offset + 2 > length) {
        return const WorkoutData.error('Поврежден пакет счетчика гребков');
      }
      strokeCount = buffer.getUint16(offset, Endian.little);
      offset += 2;
    }

    double distance = 0.0;
    if ((flags & 0x0004) != 0) {
      if (offset + 3 > length) {
        return const WorkoutData.error('Поврежден пакет дистанции гребли');
      }
      distance =
          (buffer.getUint8(offset + 2) << 16 |
                  buffer.getUint8(offset + 1) << 8 |
                  buffer.getUint8(offset))
              .toDouble();
      offset += 3;
    }

    int splitTime = 0;
    if ((flags & 0x0008) != 0) {
      if (offset + 2 > length) {
        return const WorkoutData.error('Поврежден пакет времени сплита');
      }
      splitTime = buffer.getUint16(offset, Endian.little);
      offset += 2;
    }

    double power = 0.0;
    if ((flags & 0x0010) != 0) {
      if (offset + 2 > length) {
        return const WorkoutData.error('Поврежден пакет мощности гребли');
      }
      power = buffer.getInt16(offset, Endian.little).toDouble();
      offset += 2;
    }

    int heartRate = 0;
    if ((flags & 0x0100) != 0) {
      if (offset + 1 <= length) {
        heartRate = buffer.getUint8(offset);
      }
    }

    return WorkoutData(
      equipmentName: '$deviceName (Rower)',
      heartRate: iosHeartRate ?? heartRate,
      distance: distance,
      duration: 0,
      energy: 0.0,
      strokeRate: strokeRate,
      strokeCount: strokeCount,
      splitTime500m: splitTime,
      bikePower: power,
    );
  }
}
