// FILE: lib/core/ble_parsers/models/workout_data.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_data.freezed.dart';

@freezed
class WorkoutData with _$WorkoutData {
  const factory WorkoutData({
    required String equipmentName,
    required int heartRate, // Пульс (BPM) - общий для всех
    required double distance, // Дистанция (Метры) - общая для всех
    required int duration, // Общая длительность (Секунды)
    required double energy, // Сожженные калории (ккал)
    // 🚣 РУЧНОЙ/ИНТЕГРИРОВАННЫЙ ГРЕБНОЙ ТРЕНАЖЕР (Rower - UUID 0x2AD1)
    @Default(0.0) double strokeRate, // Темп гребков (SPM)
    @Default(0) int strokeCount, // Всего гребков
    @Default(0) int splitTime500m, // Время на 500 метров в секундах
    @Default(0.0) double strokeLength, // Длина гребка (Метры)
    // 🚴 ВЕЛОТРЕНАЖЕР / САЙКЛ (Indoor Bike - UUID 0x2AD2)
    @Default(0.0) double cadence, // Каденс (RPM)
    @Default(0.0) double bikePower, // Мощность (Ватт)
    @Default(0.0) double ftp, // Расчетная Functional Threshold Power
    @Default(0.0) double wattsPerKg, // Соотношение мощности к весу (Вт/кг)
    @Default(0) int resistanceLevel, // Уровень сопротивления
    // 🏃 БЕГОВАЯ ДОРОЖКА (Treadmill - UUID 0x2ACD)
    @Default(0.0) double speed, // Скорость (км/ч)
    @Default(0) int runPaceSeconds, // Темп бега (секунд на 1 километр)
    @Default(0.0) double runCadence, // Каденс бега (шагов в минуту / SPM)
    @Default(0.0) double incline, // Угол наклона (%)
    @Default(0.0) double contactTime, // Время контакта стопы с базой (мс)
    // 🪜 СТЕППЕРЫ И КЛАЙМБЕРЫ (Stair Climber - UUID 0x2AD0 / Stepper - 0x2ACF)
    @Default(0) int floorsCount, // Количество пройденных этажей
    @Default(0.0) double stepRate, // Скорость шагов в минуту (SPM)
    @Default(0.0) double verticalAscent, // Высота подъема (Метры)
  }) = _WorkoutData;

  const factory WorkoutData.error(String errorMessage) = _WorkoutDataError;
}
