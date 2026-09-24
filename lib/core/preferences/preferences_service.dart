// FILE: .\lib\core\preferences\preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  final SharedPreferences _prefs;

  static const String _keyThemeMode = 'theme_mode';
  // ДОБАВЛЕНО: Ключ для сохранения пороговой мощности
  static const String _keyFtpValue = 'user_ftp_value';

  PreferencesService(this._prefs);

  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'dark';
  }

  // ДОБАВЛЕНО: Сохранить новое значение FTP
  Future<void> saveFtpValue(double value) async {
    await _prefs.setDouble(_keyFtpValue, value);
  }

  // ДОБАВЛЕНО: Получить FTP. Дефолтное значение для новичка — 150 Вт
  double getFtpValue() {
    return _prefs.getDouble(_keyFtpValue) ?? 150.0;
  }
}
