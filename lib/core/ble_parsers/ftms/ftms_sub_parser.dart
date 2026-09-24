// FILE: .\lib\core\ble_parsers\ftms\ftms_sub_parser.dart
import 'dart:typed_data';

import '../models/workout_data.dart';

abstract class FtmsSubParser {
  WorkoutData parse(
    ByteData buffer,
    int length,
    int? iosHeartRate,
    String deviceName,
  );
}
