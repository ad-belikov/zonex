// FILE: .\lib\main.dart
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/injection.dart';

void main() async {
  // ИСПРАВЛЕНО: Добавлен ключевой словой async
  WidgetsFlutterBinding.ensureInitialized();

  // ИСПРАВЛЕНО: Ждем, пока проинициализируются настройки SharedPreferences в DI
  await setupDependencies();

  runApp(const ZonExApp());
}
