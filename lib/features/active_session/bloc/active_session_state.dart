// FILE: .\lib\features\active_session\bloc\active_session_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/ble_parsers/ble_parser.dart'; // Нужен для EquipmentType

part 'active_session_state.freezed.dart';

@Freezed()
sealed class ActiveSessionState with _$ActiveSessionState {
  const factory ActiveSessionState.initial() = _Initial;

  const factory ActiveSessionState.data({
    @Default(EquipmentType.unknown) EquipmentType equipmentType,
    @Default('Тренажер') String equipmentName,
    @Default(0) int heartRate,
    @Default(0.0) double distance,

    // Метрики гребли (Rower)
    @Default(0.0) double strokeRate,
    @Default(0) int strokeCount,
    @Default('0:00') String formattedPace,
    @Default(0.0) double rowerPower,

    // Метрики Велосипеда (Bike)
    @Default(0.0) double bikeSpeed,
    @Default(0.0) double bikeCadence,
    @Default(0.0) double bikePower,
    @Default(0) int resistanceLevel,

    // Метрики Дорожки (Treadmill)
    @Default(0.0) double runSpeed,
    @Default('0:00') String runPace,
    @Default(0.0) double runCadence,
    @Default(0.0) double incline,

    // Метрики Степпера (Stepper)
    @Default(0) int floorsCount,
    @Default(0.0) double stepRate,
  }) = _Data;

  const factory ActiveSessionState.finished() = _Finished;
}
