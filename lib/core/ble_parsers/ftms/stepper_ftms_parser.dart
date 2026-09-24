// FILE: .\lib\core\ble_parsers\ftms\stepper_ftms_parser.dart
import 'dart:typed_data';

import '../models/workout_data.dart';
import 'ftms_sub_parser.dart';

class StepperFtmsParser implements FtmsSubParser {
  @override
  WorkoutData parse(
    ByteData buffer,
    int length,
    int? iosHeartRate,
    String deviceName,
  ) {
    if (length < 2) {
      return const WorkoutData.error('Пакет Stepper слишком короткий');
    }

    final int flags = buffer.getUint16(0, Endian.little);
    int offset = 2;

    double stepRate = 0.0;
    if ((flags & 0x0001) == 0) {
      if (offset + 2 > length) {
        return const WorkoutData.error('Поврежден пакет частоты шагов');
      }
      stepRate = buffer.getUint16(offset, Endian.little).toDouble();
      offset += 2;
    }

    int floorsCount = 0;
    if ((flags & 0x0002) != 0) {
      if (offset + 2 > length) {
        return const WorkoutData.error('Поврежден пакет счетчика этажей');
      }
      floorsCount = buffer.getUint16(offset, Endian.little);
      offset += 2;
    }

    double verticalAscent = 0.0;
    if ((flags & 0x0004) != 0) {
      if (offset + 2 > length) {
        return const WorkoutData.error('Поврежден пакет высоты подъема');
      }
      verticalAscent = buffer.getUint16(offset, Endian.little) * 0.1;
      offset += 2;
    }

    double distance = 0.0;
    if ((flags & 0x0008) != 0) {
      if (offset + 3 > length) {
        return const WorkoutData.error('Поврежден пакет дистанции степпера');
      }
      distance =
          (buffer.getUint8(offset + 2) << 16 |
                  buffer.getUint8(offset + 1) << 8 |
                  buffer.getUint8(offset))
              .toDouble();
      offset += 3;
    }

    int heartRate = 0;
    if ((flags & 0x0040) != 0) {
      if (offset + 1 <= length) {
        heartRate = buffer.getUint8(offset);
      }
    }

    return WorkoutData(
      equipmentName: '$deviceName (Stepper/Climber)',
      heartRate: iosHeartRate ?? heartRate,
      distance: distance,
      duration: 0,
      energy: 0.0,
      floorsCount: floorsCount,
      stepRate: stepRate,
      verticalAscent: verticalAscent,
    );
  }
}
