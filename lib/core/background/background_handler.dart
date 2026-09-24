// FILE: lib/core/background/background_handler.dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Инициализация фонового обработчика (вызывается нативным слоем)
@pragma('vm:entry-point') // Обязательная аннотация, чтобы линтер не вырезал метод при компиляции релиз-сборки
void startCallback() {
  FlutterForegroundTask.setTaskHandler(WorkoutBackgroundHandler());
}

class WorkoutBackgroundHandler extends TaskHandler {
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Вызывается при остановке фоновой службы (вручную или по таймауту системы).
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Вызывается автоматически на основе интервала времени.
    // Оставляем пустым, так как основной поток BLE живет в UI-изоляте приложения.
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Вызывается в момент фактического запуска фонового процесса.
    // При необходимости можно проверить, кто запустил службу:
    // if (starter == TaskStarter.developer) { ... }
  }
}
