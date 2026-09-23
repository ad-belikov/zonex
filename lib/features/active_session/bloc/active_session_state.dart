abstract class ActiveSessionState {}

// ДОБАВЛЕНО: Состояние покоя, когда тренировка еще не запущена
class ActiveSessionInitial extends ActiveSessionState {}

// ДОБАВЛЕНО: Состояние активного стриминга очищенных данных тренировки
class ActiveSessionData extends ActiveSessionState {
  final double strokeRate; // Частота гребков (SPM)
  final int strokeCount; // Всего гребков
  final double distance; // Дистанция (метры)
  final double power; // Мощность (Ватт)
  final int heartRate; // Пульс (BPM)
  final String formattedPace; // Форматированный темп (ММ:СС)

  ActiveSessionData({
    required this.strokeRate,
    required this.strokeCount,
    required this.distance,
    required this.power,
    required this.heartRate,
    required this.formattedPace,
  });
}

// ДОБАВЛЕНО: Состояние завершения сессии
class ActiveSessionFinished extends ActiveSessionState {}
