import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _rememberMeKey = 'remember_me';
  static const String _themeModeKey = 'theme_mode';

  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> saveUserJson(String value) async {
    await saveString(_userKey, value);
  }

  static Future<String?> getUserJson() async {
    return getString(_userKey);
  }

  static Future<void> setRememberMe(bool value) async {
    await saveBool(_rememberMeKey, value);
  }

  static Future<bool> getRememberMe() async {
    return await getBool(_rememberMeKey) ?? false;
  }

  static Future<void> saveThemeMode(String value) async {
    await saveString(_themeModeKey, value);
  }

  static Future<String?> getThemeMode() async {
    return getString(_themeModeKey);
  }
}
